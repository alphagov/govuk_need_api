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
  field :monthly_user_contacts, type: Integer
  field :monthly_site_views, type: Integer
  field :monthly_need_views, type: Integer
  field :monthly_searches, type: Integer
  field :currently_met, type: Boolean
  field :other_evidence, type: String
  field :legislation, type: String

  after_update :record_update_revision
  after_create :record_create_revision

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

  validates :role, presence: true
  validates :goal, presence: true
  validates :benefit, presence: true
  validates_numericality_of :monthly_user_contacts, :greater_than_or_equal_to => 0, :allow_nil => true, :only_integer => true
  validates_numericality_of :monthly_site_views, :greater_than_or_equal_to => 0, :allow_nil => true, :only_integer => true
  validates_numericality_of :monthly_need_views, :greater_than_or_equal_to => 0, :allow_nil => true, :only_integer => true
  validates_numericality_of :monthly_searches, :greater_than_or_equal_to => 0, :allow_nil => true, :only_integer => true

  validate :organisation_ids_must_exist

  has_and_belongs_to_many :organisations
  has_many :revisions, class_name: "NeedRevision"

  def save_as(user)
    action = new_record? ? "create" : "update"

    if saved = save_without_callbacks
      record_revision(action, user)
    end
    saved
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
end
