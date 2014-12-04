require_relative '../test_helper'

class NeedStatusTest < ActiveSupport::TestCase
  should validate_presence_of(:description)
  should validate_inclusion_of(:description).in_array([NeedStatus::PROPOSED, "out of scope", NeedStatus::NOT_VALID, NeedStatus::VALID, NeedStatus::VALID_WITH_CONDITIONS])

  should allow_value("abc").for(:additional_comments)

  should "validate that invalid needs have reasons why they're invalid" do
    refute NeedStatus.new(description: NeedStatus::NOT_VALID, reasons: []).valid?
    assert NeedStatus.new(description: NeedStatus::NOT_VALID, reasons: ["abc"]).valid?
    assert NeedStatus.new(description: NeedStatus::PROPOSED, reasons: nil).valid?
  end

  should "validate that needs that are valid with conditions have validation conditions" do
    refute NeedStatus.new(description: NeedStatus::VALID_WITH_CONDITIONS, validation_conditions: nil).valid?
    assert NeedStatus.new(description: NeedStatus::VALID_WITH_CONDITIONS, validation_conditions: "abc").valid?
    assert NeedStatus.new(description: NeedStatus::PROPOSED, validation_conditions: nil).valid?
  end
end
