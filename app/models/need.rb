class Need
  include Mongoid::Document

  field :role, type: String
  field :goal, type: String
  field :benefit, type: String
  field :organisation_ids, type: Array, default: []
  field :justifications, type: Array
  field :impact, type: String
  field :met_when, type: Array
  field :monthly_user_contacts, type: Integer
  field :site_views, type: Integer
  field :need_views, type: Integer
  field :searched_for, type: Integer
  field :currently_online, type: Boolean
  field :other_evidence, type: String
  field :legislation, type: Array

  validates :role, presence: true
  validates :goal, presence: true
  validates :benefit, presence: true
  validates_numericality_of :monthly_user_contacts, :greater_than_or_equal_to => 0, :allow_nil => true, :only_integer => true
  validates_numericality_of :site_views, :greater_than_or_equal_to => 0, :allow_nil => true, :only_integer => true
  validates_numericality_of :need_views, :greater_than_or_equal_to => 0, :allow_nil => true, :only_integer => true
  validates_numericality_of :searched_for, :greater_than_or_equal_to => 0, :allow_nil => true, :only_integer => true

  validate :organisation_ids_must_exist

  has_and_belongs_to_many :organisations

  private
  def organisation_ids_must_exist
    org_ids = (organisation_ids || []).uniq

    if Organisation.where(:id.in => org_ids).count < org_ids.size
      errors.add(:organisation_ids, "must exist")
    end
  end
end
