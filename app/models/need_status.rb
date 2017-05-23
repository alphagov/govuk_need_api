class NeedStatus
  PROPOSED = "proposed".freeze
  NOT_VALID = "not valid".freeze
  VALID = "valid".freeze
  VALID_WITH_CONDITIONS = "valid with conditions".freeze

  include Mongoid::Document

  embedded_in :need

  field :description, type: String
  field :reasons, type: Array
  field :additional_comments, type: String
  field :validation_conditions, type: String

  validates :description, presence: true, inclusion: { in: [PROPOSED, NOT_VALID, VALID, VALID_WITH_CONDITIONS] }

  validates :reasons, presence: true, if: Proc.new { |s| s.description == NOT_VALID }
  validates :validation_conditions, presence: true, if: Proc.new { |s| s.description == VALID_WITH_CONDITIONS }

  before_validation :clear_inconsistent_fields

private

  def clear_inconsistent_fields
    self.reasons = nil if description != NOT_VALID && reasons != nil

    if description != VALID && additional_comments != nil
      self.additional_comments = nil
    end

    if description != VALID_WITH_CONDITIONS && validation_conditions != nil
      self.validation_conditions = nil
    end
  end
end
