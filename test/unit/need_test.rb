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
        yearly_user_contacts: 1000,
        yearly_site_views: 10000,
        yearly_need_views: 1000,
        yearly_searches: 2000,
        other_evidence: "Other evidence",
        legislation: "link#1\nlink#2",
        applies_to_all_organisations: false
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
      assert_equal 1000, need.yearly_user_contacts
      assert_equal 10000, need.yearly_site_views
      assert_equal 1000, need.yearly_need_views
      assert_equal 2000, need.yearly_searches
      assert_equal "Other evidence", need.other_evidence
      assert_equal "link#1\nlink#2", need.legislation
      assert_equal false, need.applies_to_all_organisations
    end

    context "assigning need ids" do
      should "assign an incremented identifier to a new need, starting at 100001" do
        need_one = Need.create!(@atts)
        need_two = Need.create!(@atts)

        assert_equal 100001, need_one.need_id
        assert_equal 100002, need_two.need_id

        need_three = Need.new(@atts)
        need_three.need_id = 100005
        need_three.save!
        need_four = Need.create!(@atts)

        assert_equal 100005, need_three.need_id
        assert_equal 100006, need_four.need_id
      end

      should "not permit two needs to have the same id" do
        need_one = Need.new(@atts.merge(role: "Need one"))
        need_two = Need.new(@atts.merge(role: "Need two"))

        need_one.need_id = 123456
        need_two.need_id = 123456

        assert need_one.save
        assert_raise Mongo::OperationFailure do
          need_two.save
        end

        assert need_one.persisted?
        refute need_two.persisted?

        need_one.reload

        assert_equal 123456, need_one.need_id
      end

      should "set the record ID to be the need ID" do
        need_one = Need.create!(@atts)
        need_one.reload

        assert_equal 100001, need_one.need_id
        assert_equal "100001", need_one.id
      end

      should "not assign a need ID until creation" do
        need = Need.new(@atts.merge(:organisation_ids => []))
        assert need.valid?
        assert_nil need.need_id
        need.save!
        refute_nil need.need_id
      end
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

    should "be invalid if yearly contacts is not a positive integer" do
      need = Need.new(@atts.merge(:yearly_user_contacts => -10))

      refute need.valid?
      assert need.errors.has_key?(:yearly_user_contacts)
    end

    should "be invalid if yearly site views is not a positive integer" do
      need = Need.new(@atts.merge(:yearly_site_views => -10))

      refute need.valid?
      assert need.errors.has_key?(:yearly_site_views)
    end

    should "be invalid if yearly need views is not a positive integer" do
      need = Need.new(@atts.merge(:yearly_need_views => -10))

      refute need.valid?
      assert need.errors.has_key?(:yearly_need_views)
    end

    should "be invalid if yearly searches for this need is not a positive integer" do
      need = Need.new(@atts.merge(:yearly_searches => -10))

      refute need.valid?
      assert need.errors.has_key?(:yearly_searches)
    end

    should "be valid with no organisations" do
      need = Need.new(@atts.merge(:organisation_ids => nil))
      assert need.valid?

      need = Need.new(@atts.merge(:organisation_ids => []))
      assert need.valid?
    end

    should "default applies_to_all_organisations to false" do
      need = Need.create!(@atts.merge(applies_to_all_organisations: nil))
      need.reload

      assert_equal false, need.applies_to_all_organisations
    end

    should "disallow applies_to_all_organisations with explicit organisations" do
      need_atts = @atts.merge(
        applies_to_all_organisations: true,
        organisation_ids: ["cabinet-office"]
      )
      need = Need.new(need_atts)
      refute need.valid?
    end

    should "allow applies_to_all_organisations with no organisations" do
      need_atts = @atts.merge(
        applies_to_all_organisations: true,
        organisation_ids: []
      )
      need = Need.new(need_atts)
      assert need.valid?
    end

    should "allow applies_to_all_organisations with organisation IDs not set" do
      need_atts = @atts.merge(applies_to_all_organisations: true)
        .except(:organisation_ids)
      need = Need.new(need_atts)
      assert need.valid?
    end

    context "creating revisions" do
      should "create an initial revision when given valid attributes" do
        need = Need.new(@atts.merge(goal: "get a premises licence"))
        need.save
        need.reload

        assert_equal 1, need.revisions.count

        revision = need.revisions.first
        assert_equal "create", revision.action_type
        assert_equal "get a premises licence", revision.snapshot["goal"]
        assert_nil revision.author
      end

      should "store user information in the revision if provided" do
        need = Need.new(@atts.merge(goal: "get a premises licence"))
        need.save_as(name: "Winston Smith-Churchill", email: "winston@alphagov.co.uk")
        need.reload

        assert_equal 1, need.revisions.count

        revision = need.revisions.first
        assert_equal "create", revision.action_type
        assert_equal "get a premises licence", revision.snapshot["goal"]
        assert_equal "Winston Smith-Churchill", revision.author["name"]
        assert_equal "winston@alphagov.co.uk", revision.author["email"]
      end

      should "not create a revision if not saved" do
        need = Need.new(@atts.merge(role: ""))

        refute need.save
        refute need.save_as(name: "Winston Smith-Churchill", email: "winston@alphagov.co.uk")

        assert_equal 0, need.revisions.count
      end
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

  context "updating a need" do
    setup do
      @need = FactoryGirl.create(:need, goal: "pay my car tax") # creates an initial revision

      # set the timestamp to be explicitly different so that the return order can be
      # assured for the subsequent tests
      @need.revisions.first.update_attribute(:created_at, Date.parse("2001-01-01"))
    end

    should "persist the changes" do
      @need.goal = "find travel advice for Turks and Caicos Islands"
      assert @need.save_as(name: "Winston Smith-Churchill", email: "winston@alphagov.co.uk")

      @need.reload

      assert_equal "find travel advice for Turks and Caicos Islands", @need.goal
    end

    should "create a new revision of the need" do
      @need.goal = "find travel advice for Germany"
      @need.save

      @need.reload

      assert_equal "find travel advice for Germany", @need.goal
      assert_equal 2, @need.revisions.count

      revision = @need.revisions.first
      assert_equal "update", revision.action_type
      assert_equal "find travel advice for Germany", revision.snapshot["goal"]
      assert_nil revision.author
    end

    should "save user information in the revision if provided" do
      @need.goal = "find travel advice for Portugal"
      @need.save_as(name: "Winston Smith-Churchill", email: "winston@alphagov.co.uk")

      @need.reload

      assert_equal "find travel advice for Portugal", @need.goal
      assert_equal 2, @need.revisions.count

      revision = @need.revisions.first
      assert_equal "update", revision.action_type
      assert_equal "find travel advice for Portugal", revision.snapshot["goal"]
      assert_equal "Winston Smith-Churchill", revision.author["name"]
      assert_equal "winston@alphagov.co.uk", revision.author["email"]
    end

    should "not create a new revision if not saved" do
      @need.role = ""

      refute @need.save
      refute @need.save_as(name: "Winston Smith-Churchill", email: "winston@alphagov.co.uk")

      @need.reload

      assert_equal "pay my car tax", @need.goal
      assert_equal 1, @need.revisions.count
    end
  end

end
