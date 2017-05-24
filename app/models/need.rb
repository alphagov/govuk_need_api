class Need
  include Mongoid::Document

  INITIAL_NEED_ID = 100001

  field :_id, type: String, default: -> { need_id }
  field :need_id, type: Integer
  field :content_id, type: String, default: -> { SecureRandom.uuid }
  field :role, type: String
  field :goal, type: String
  field :benefit, type: String
  field :organisation_ids, type: Array, default: []
  field :justifications, type: Array
  field :impact, type: String
  field :met_when, type: Array
  field :yearly_user_contacts, type: Integer
  field :yearly_site_views, type: Integer
  field :yearly_need_views, type: Integer
  field :yearly_searches, type: Integer
  field :other_evidence, type: String
  field :legislation, type: String
  field :applies_to_all_organisations, type: Boolean, default: false
  field :duplicate_of, type: Integer, default: nil

  embeds_one :status, class_name: "NeedStatus", inverse_of: :need, cascade_callbacks: true
  validates :status, presence: true
  validates_associated :status

  before_validation :default_booleans_to_false
  before_validation :default_status_to_proposed
  after_update :record_update_revision
  after_create :record_create_revision

  default_scope -> { order_by(:_id.desc) }

  PAGE_SIZE = 50
  paginates_per PAGE_SIZE

  # This callback needs to be assigned before the `key` class method below, as
  # otherwise Mongoid will generate a new document's key before it assigns a
  # new need ID. Normally, ActiveModel would ensure `before_x` callbacks were
  # invoked before `around_x` callbacks, but apparently not in this case.
  #
  # See: <http://edgeguides.rubyonrails.org/active_record_callbacks.html>
  #      <http://two.mongoid.org/docs/callbacks.html>
  before_save :assign_new_id, on: :create

  index duplicate_of: 1
  index organisation_ids: 1

  # uniqueness constraint to avoid simple forms of duplication
  index({ role: 1, goal: 1, benefit: 1 }, unique: true)

  validates :role, :goal, :benefit, presence: true
  validates :yearly_user_contacts, :yearly_site_views, :yearly_need_views, :yearly_searches,
            numericality: {
              greater_than_or_equal_to: 0, allow_nil: true, only_integer: true
            }

  validate :organisation_ids_must_exist
  validate :no_organisations_if_applies_to_all
  validate :validate_duplicate

  has_and_belongs_to_many :organisations
  has_many :revisions, class_name: "NeedRevision", inverse_of: :need

  def save_as(user)
    action = new_record? ? "create" : "update"
    save_with_revision(action, user)
  end

  def close(canonical_id, user)
    self.duplicate_of = canonical_id
    save_with_revision("close", user)
  end

  def reopen(user)
    self.duplicate_of = nil
    save_with_revision("reopen", user)
  end

  def save_with_revision(action, user)
    saved = save_without_callbacks
    record_revision(action, user) if saved
    saved
  end

  def has_duplicates?
    if need_id
      Need.where(duplicate_of: need_id).exists?
    else
      false
    end
  end

  def closed?
    duplicate_of.present?
  end

  def save(*args)
    super
  rescue Mongo::Error::OperationFailure => e
    if e.message =~ /E11000/ # Duplicate key error
      errors.add(:base, "This need already exists")
      return false
    else
      raise
    end
  end

private

  def assign_new_id
    last_assigned = Need.order_by(:need_id.desc).first
    self.need_id ||= increment_last_assigned_need_id?(last_assigned) ? last_assigned.need_id + 1 : INITIAL_NEED_ID
    self._id = self.need_id
  end

  def increment_last_assigned_need_id?(last_assigned)
    last_assigned.present? && last_assigned.need_id >= INITIAL_NEED_ID
  end

  def organisation_ids_must_exist
    org_ids = (organisation_ids || []).uniq
    if Organisation.any_in(_id: org_ids).count < org_ids.size
      errors.add(:organisation_ids, "must exist")
    end
  end

  def no_organisations_if_applies_to_all
    if applies_to_all_organisations && organisation_ids.present?
      errors.add(
        :organisation_ids,
        "cannot exist if applies_to_all_organisations is set"
      )
    end
  end

  def default_status_to_proposed
    self.status ||= NeedStatus.new(description: NeedStatus::PROPOSED)
  end

  def validate_duplicate
    return unless duplicate_of.present?
    canonical_need = Need.where(need_id: duplicate_of).first
    # There are various criteria for being a valid duplicate:
    # the least obvious crierion is to not allow duplicate chains
    # i.e. A -> B -> C
    if canonical_need.nil?
      errors.add(
        :duplicate_of,
        "The need ID doesn't exist"
      )
    elsif duplicate_of == need_id
      errors.add(
        :duplicate_of,
        "A need cannot be a duplicate of itself"
      )
    elsif has_duplicates?
      errors.add(
        :duplicate_of,
        "This need has duplicates, it can not be marked as a duplicate of another need"
      )
    elsif canonical_need.duplicate_of.present?
      errors.add(
        :duplicate_of,
        "The need ID is already a duplicate of another need"
      )
    end
  end

  def record_create_revision
    prevent_additional_callbacks { record_revision "create" }
  end

  def record_update_revision
    prevent_additional_callbacks { record_revision "update" }
  end

  def record_revision(action, user = nil)
    revisions.create(
      action_type: action,
      snapshot: attributes,
      author: user
    )
  end

  def prevent_additional_callbacks
    if @prevent_additional_callbacks_guard.nil?
      @prevent_additional_callbacks_guard = 'on guard'
      yield
      @prevent_additional_callbacks_guard = nil
    end
  end

  # It is necessary to save without callbacks here so that we can create a
  # revision with extra attributes (eg user info) using the save_as method
  # without duplicate revisions being created.
  #
  def save_without_callbacks
    Need.skip_callback(:create, :after, :record_create_revision)
    Need.skip_callback(:update, :after, :record_update_revision)

    save_status = save

    Need.set_callback(:create, :after, :record_create_revision)
    Need.set_callback(:update, :after, :record_update_revision)

    save_status
  end

  def default_booleans_to_false
    self.applies_to_all_organisations ||= false

    # return nil here so that it doesn't break the callback chain
    nil
  end
end
