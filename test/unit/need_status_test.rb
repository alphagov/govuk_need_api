require_relative '../test_helper'

class NeedStatusTest < ActiveSupport::TestCase
  should validate_presence_of(:description)
  should validate_inclusion_of(:description).in_array(["proposed", "out of scope", "not valid", "valid"])

  should allow_value("abc").for(:additional_comments)

  should "validate that invalid needs have reasons why they're invalid" do
    refute NeedStatus.new(description: "not valid", reasons: []).valid?
    assert NeedStatus.new(description: "not valid", reasons: ["abc"]).valid?
    assert NeedStatus.new(description: "proposed", reasons: nil).valid?
  end
end
