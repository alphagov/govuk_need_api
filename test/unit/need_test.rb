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
        met_when: ["criteria #1", "criteria #2"],
        monthly_user_contacts: 1000,
        site_views: 10000,
        need_views: 1000,
        searched_for: 2000,
        currently_online: false,
        other_evidence: "Other evidence",
        legislation: ["link#1","link#2"]
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
      assert_equal 1000, need.monthly_user_contacts
      assert_equal 10000, need.site_views
      assert_equal 1000, need.need_views
      assert_equal 2000, need.searched_for
      assert_equal false, need.currently_online
      assert_equal "Other evidence", need.other_evidence
      assert_equal ["link#1","link#2"], need.legislation
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

    should "be invalid if monthly contacts is not a positive integer" do
      need = Need.new(@atts.merge(:monthly_user_contacts => -10))

      refute need.valid?
      assert need.errors.has_key?(:monthly_user_contacts)
    end

    should "be invalid if monthly site views is not a positive integer" do
      need = Need.new(@atts.merge(:site_views => -10))

      refute need.valid?
      assert need.errors.has_key?(:site_views)
    end

    should "be invalid if monthly need views is not a positive integer" do
      need = Need.new(@atts.merge(:need_views => -10))

      refute need.valid?
      assert need.errors.has_key?(:need_views)
    end

    should "be invalid if monthly searches for this need is not a positive integer" do
      need = Need.new(@atts.merge(:searched_for => -10))

      refute need.valid?
      assert need.errors.has_key?(:searched_for)
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
