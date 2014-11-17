class NeedStatus
  include Mongoid::Document

  embedded_in :need

  field :description, type: String
  field :reason, type: String # this field is deprecated and will be removed soon
  field :reasons, type: Array

  validates :description, presence: true, inclusion: { in: ["proposed", "out of scope", "not valid"] }

  validates :reasons, presence: true, if: Proc.new { |s| s.description == "not valid" }
end
