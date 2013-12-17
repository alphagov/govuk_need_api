class Need
  include Mongoid::Document

  INITIAL_NEED_ID = 100001

  field :need_id, type: Integer
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
  field :in_scope, type: Boolean
  field :duplicate_of, type: Integer, default: nil

  before_validation :default_booleans_to_false
  after_update :record_update_revision
  after_create :record_create_revision

  default_scope order_by([:_id, :desc])

  paginates_per 50

  # This callback needs to be assigned before the `key` class method below, as
  # otherwise Mongoid will generate a new document's key before it assigns a
  # new need ID. Normally, ActiveModel would ensure `before_x` callbacks were
  # invoked before `around_x` callbacks, but apparently not in this case.
  #
  # See: <http://edgeguides.rubyonrails.org/active_record_callbacks.html>
  #      <http://two.mongoid.org/docs/callbacks.html>
  before_save :assign_new_id, on: :create

  # Use need_id as the internal Mongo ID; see http://two.mongoid.org/docs/extras.html
  key :need_id
  index :duplicate_of

  index :organisation_ids

  validates :role, presence: true
  validates :goal, presence: true
  validates :benefit, presence: true
  validates_numericality_of :yearly_user_contacts, :greater_than_or_equal_to => 0, :allow_nil => true, :only_integer => true
  validates_numericality_of :yearly_site_views, :greater_than_or_equal_to => 0, :allow_nil => true, :only_integer => true
  validates_numericality_of :yearly_need_views, :greater_than_or_equal_to => 0, :allow_nil => true, :only_integer => true
  validates_numericality_of :yearly_searches, :greater_than_or_equal_to => 0, :allow_nil => true, :only_integer => true

  # at current, we only allow a need to be marked as out of scope and not in scope
  validates :in_scope, inclusion: { in: [ nil,  false ] }

  validate :organisation_ids_must_exist
  validate :no_organisations_if_applies_to_all
  validate :validate_duplicate

  has_and_belongs_to_many :organisations
  has_many :revisions, class_name: "NeedRevision"

  def save_as(action, user)
    if saved = save_without_callbacks
      record_revision(action, user)
    end
    saved
  end

  def has_duplicates?
    Need.where(duplicate_of: need_id).exists?
  end

  def closed?
    duplicate_of.present?
  end

  private
  def assign_new_id
    last_assigned = Need.order_by([:need_id, :desc]).first
    self.need_id ||= (last_assigned.present? && last_assigned.need_id >= INITIAL_NEED_ID) ? last_assigned.need_id + 1 : INITIAL_NEED_ID
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

  def validate_duplicate
    return unless duplicate_of.present?
    canonical_need = Need.where(need_id: duplicate_of).first
    # There are various criteria for being a valid duplicate:
    # the least obvious crierion is to not allow duplicate chains
    # i.e. A -> B -> C
    if !canonical_need.present? ||
       duplicate_of == need_id ||
       has_duplicates? ||
       canonical_need.duplicate_of.present?
      errors.add(
        :duplicate_of,
        "Can not close this need as a duplicate"
      )
    end
  end

  def record_create_revision
    record_revision "create"
  end

  def record_update_revision
    record_revision "update"
  end

  def record_revision(action, user = nil)
    revisions.create(
      action_type: action,
      snapshot: attributes,
      author: user
    )
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
    return
  end
end
