class NeedStatus
  include Mongoid::Document

  embedded_in :need

  field :description, type: String
  field :reason, type: String

  validates :description, presence: true, inclusion: { in: ["proposed", "out of scope"] }

  validates :reason, presence: true, if: Proc.new { |s| s.description == "out of scope" }
end
