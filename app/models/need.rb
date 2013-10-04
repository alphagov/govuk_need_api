class Need
  include Mongoid::Document

  field :role, type: String
  field :goal, type: String
  field :benefit, type: String
  field :organisations, type: Array
  field :justifications, type: Array
  field :impact, type: String
  field :met_when, type: Array

  validates :role, presence: true
  validates :goal, presence: true
  validates :benefit, presence: true
end
