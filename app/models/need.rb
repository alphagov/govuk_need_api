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

  key :need_id

  validates :role, presence: true
  validates :goal, presence: true
  validates :benefit, presence: true
  validates_numericality_of :monthly_user_contacts, :greater_than_or_equal_to => 0, :allow_nil => true, :only_integer => true
  validates_numericality_of :monthly_site_views, :greater_than_or_equal_to => 0, :allow_nil => true, :only_integer => true
  validates_numericality_of :monthly_need_views, :greater_than_or_equal_to => 0, :allow_nil => true, :only_integer => true
  validates_numericality_of :monthly_searches, :greater_than_or_equal_to => 0, :allow_nil => true, :only_integer => true

  validate :organisation_ids_must_exist

  before_validation :assign_new_id, on: :create
  has_and_belongs_to_many :organisations

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
end
