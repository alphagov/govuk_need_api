class NeedStatus
  include Mongoid::Document

  embedded_in :need

  field :description, type: String

  validates :description, presence: true, inclusion: { in: ["proposed"] }
end
