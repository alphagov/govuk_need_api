class NeedStatus
  include Mongoid::Document

  embedded_in :need

  field :description, type: String
  field :reason, type: String # this field is deprecated and will be removed soon
  field :reasons, type: Array
  field :additional_comments, type: String

  validates :description, presence: true, inclusion: { in: ["proposed", "out of scope", "not valid", "valid"] }

  validates :reasons, presence: true, if: Proc.new { |s| s.description == "not valid" }

  before_save :clear_inconsistent_fields

private
  def clear_inconsistent_fields
    if description != "not valid" && reasons != nil
      self.reasons = nil
    end

    if description != "valid" && additional_comments != nil
      self.additional_comments = nil
    end
  end
end
