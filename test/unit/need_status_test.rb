require_relative '../test_helper'

class NeedStatusTest < ActiveSupport::TestCase
  should validate_presence_of(:description)
  should validate_inclusion_of(:description).in_array(["proposed"])
end
