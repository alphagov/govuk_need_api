class Need
  include Mongoid::Document

  field :role, type: String
  field :goal, type: String
  field :benefit, type: String

  validates :goal, presence: true
end
