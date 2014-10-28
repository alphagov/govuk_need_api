require_relative '../test_helper'

class NeedStatusTest < ActiveSupport::TestCase
  should validate_presence_of(:description)
  should validate_inclusion_of(:description).in_array(["proposed", "out of scope"])

  should "validate that a reason is valid if the need is out of scope" do
    refute NeedStatus.new(description: "out of scope", reason: nil).valid?
    assert NeedStatus.new(description: "out of scope", reason: "abc").valid?
  end
end
