require_relative '../test_helper'

class NeedTest < ActiveSupport::TestCase

  setup do
    FactoryGirl.create(:organisation, name: "Cabinet Office", slug: "cabinet-office")
    FactoryGirl.create(:organisation, name: "Ministry of Justice", slug: "ministry-of-justice")
  end

  context "creating a need" do
    setup do
      @atts = {
        role: "user",
        goal: "pay my car tax",
        benefit: "avoid paying a fine",
        organisation_ids: ["cabinet-office", "ministry-of-justice"],
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
      assert_equal ["cabinet-office", "ministry-of-justice"], need.organisation_ids
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
      need = Need.new(@atts.merge(:organisation_ids => ["does-not-exist"]))

      refute need.valid?
      assert need.errors.has_key?(:organisation_ids)
    end

    should "be invalid if one of the organisations does not exist" do
      need = Need.new(@atts.merge(:organisation_ids => ["cabinet-office","does-not-exist"]))

      refute need.valid?
      assert need.errors.has_key?(:organisation_ids)
    end

    should "be valid with no organisations" do
      need = Need.new(@atts.merge(:organisation_ids => nil))
      assert need.valid?

      need = Need.new(@atts.merge(:organisation_ids => []))
      assert need.valid?
    end
  end

  context "an existing need" do
    should "return organisations" do
      need = FactoryGirl.create(:need, :organisation_ids => ["cabinet-office", "ministry-of-justice"])

      assert_equal 2, need.organisations.count
      assert_equal ["Cabinet Office", "Ministry of Justice"], need.organisations.map(&:name)
      assert_equal ["cabinet-office", "ministry-of-justice"], need.organisations.map(&:id)
    end

    should "return no organisations when no ids are present" do
      need = FactoryGirl.create(:need, :organisation_ids => nil)

      assert_equal 0, need.organisations.count
      assert_equal [], need.organisations.map(&:name)
      assert_equal [], need.organisations.map(&:id)
    end
  end

end
