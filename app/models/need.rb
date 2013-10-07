class Need
  include Mongoid::Document

  field :role, type: String
  field :goal, type: String
  field :benefit, type: String
  field :organisation_ids, type: Array
  field :justifications, type: Array
  field :impact, type: String
  field :met_when, type: Array

  validates :role, presence: true
  validates :goal, presence: true
  validates :benefit, presence: true

  validate :organisation_ids_must_exist

  private
  def organisation_ids_must_exist
    org_ids = (organisation_ids || []).uniq

    if Organisation.where(:id.in => org_ids).count < org_ids.size
      errors.add(:organisation_ids, "must exist")
    end
  end
end
