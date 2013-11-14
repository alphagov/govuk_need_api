class Organisation
  include Mongoid::Document

  field :name, type: String
  field :slug, type: String
  field :govuk_status, type: String
  field :abbreviation, type: String
  field :parent_ids, type: Array
  field :child_ids, type: Array

  key :slug

  validates :name, :slug, presence: true
  validates :slug, uniqueness: { case_sensitive: false }

  scope :in_name_order, order_by(:name => :asc)
end
