require_relative '../test_helper'

class NeedTest < ActiveSupport::TestCase

  context "creating a need" do
    setup do
      @atts = {
        role: "user",
        goal: "pay my car tax",
        benefit: "avoid paying a fine",
        organisations: ["cabinet-office"],
        justifications: ["legislation","other"],
        impact: "Noticed by an expert audience",
        met_when: ["criteria #1", "criteria #2"]
      }
    end

    should "create a need with valid attributes" do
      need = Need.new(@atts)

      assert need.valid?
      assert need.save

      need.reload

      assert_equal "user", need.role
      assert_equal "pay my car tax", need.goal
      assert_equal "avoid paying a fine", need.benefit
      assert_equal ["cabinet-office"], need.organisations
      assert_equal ["legislation", "other"], need.justifications
      assert_equal "Noticed by an expert audience", need.impact
      assert_equal ["criteria #1", "criteria #2"], need.met_when
    end

    should "be invalid without a goal" do
      need = Need.new(@atts.merge(:goal => ""))

      refute need.valid?
      assert need.errors.has_key?(:goal)
    end
  end

end
