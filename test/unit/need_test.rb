require_relative '../test_helper'

class NeedTest < ActiveSupport::TestCase

  context "creating a need" do
    setup do
      FactoryGirl.create(:organisation, slug: "cabinet-office")
      FactoryGirl.create(:organisation, slug: "ministry-of-justice")

      @atts = {
        role: "user",
        goal: "pay my car tax",
        benefit: "avoid paying a fine",
        organisations: ["cabinet-office", "ministry-of-justice"],
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
      assert_equal ["cabinet-office", "ministry-of-justice"], need.organisations
      assert_equal ["legislation", "other"], need.justifications
      assert_equal "Noticed by an expert audience", need.impact
      assert_equal ["criteria #1", "criteria #2"], need.met_when
    end

    should "be invalid without a goal" do
      need = Need.new(@atts.merge(:goal => ""))

      refute need.valid?
      assert need.errors.has_key?(:goal)
    end

    should "be invalid if the organisation does not exist" do
      need = Need.new(@atts.merge(:organisations => ["does-not-exist"]))

      refute need.valid?
      assert need.errors.has_key?(:organisations)
    end

    should "be invalid if one of the organisations does not exist" do
      need = Need.new(@atts.merge(:organisations => ["cabinet-office","does-not-exist"]))

      refute need.valid?
      assert need.errors.has_key?(:organisations)
    end

    should "be valid with no organisations" do
      need = Need.new(@atts.merge(:organisations => nil))
      assert need.valid?

      need = Need.new(@atts.merge(:organisations => []))
      assert need.valid?
    end
  end

end
