require_relative '../test_helper'

class NeedTest < ActiveSupport::TestCase
  def set_duplicate(need, canonical_id)
    need.close(canonical_id,
               name: "Winston Smith-Churchill",
               email: "winston@alphagov.co.uk")
  end

  def reopen(need)
    need.reopen(name: "Winston Smith-Churchill",
                email: "winston@alphagov.co.uk")
    need.reload
  end

  context "creating a need" do
    setup do
      create(:organisation, name: "Cabinet Office", slug: "cabinet-office")
      create(:organisation, name: "Ministry of Justice", slug: "ministry-of-justice")

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
        applies_to_all_organisations: false,
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
      assert_equal NeedStatus::PROPOSED, need.status["description"]
    end

    context "assigning need ids" do
      should "assign an incremented identifier to a new need, starting at 100001" do
        need_one = create(:need)
        need_two = create(:need, role: "Need two")

        assert_equal 100001, need_one.need_id
        assert_equal 100002, need_two.need_id

        need_three = create(:need, role: "Need three")
        need_three.need_id = 100005
        need_three.save!
        need_four = create(:need, role: "Need four")

        assert_equal 100005, need_three.need_id
        assert_equal 100006, need_four.need_id
      end

      should "not permit two needs to have the same id" do
        need_one, need_two = build_list(:need, 2)

        need_one.need_id = 123456
        need_two.need_id = 123456

        assert need_one.save
        refute need_two.save

        assert need_one.persisted?
        refute need_two.persisted?

        need_one.reload

        assert_equal 123456, need_one.need_id
      end

      should "set the record ID to be the need ID" do
        need_one = create(:need)

        assert_equal 100001, need_one.need_id
        assert_equal "100001", need_one.id
      end

      should "not assign a need ID until creation" do
        need = build(:need, :organisation_ids => [])
        assert need.valid?
        assert_nil need.need_id
        need.save!
        refute_nil need.need_id
      end
    end

    should "default applies_to_all_organisations to false" do
      need = create(:need, applies_to_all_organisations: nil)

      assert_equal false, need.applies_to_all_organisations
    end

    should "disallow applies_to_all_organisations with explicit organisations" do
      need = build(:need,
        applies_to_all_organisations: true,
        organisation_ids: ["cabinet-office"]
      )
      refute need.valid?
    end

    should "allow applies_to_all_organisations with no organisations" do
      need = build(:need,
        applies_to_all_organisations: true,
        organisation_ids: []
      )
      assert need.valid?
    end

    should "allow applies_to_all_organisations with organisation IDs not set" do
      need = build(:need, applies_to_all_organisations: true, organisation_ids: nil)
      assert need.valid?
    end

    context "with indexes set up" do
      setup do
        # Make sure the indexes are set up to the current version
        Need.collection.drop_indexes
        Need.create_indexes
      end

      should "not save if an identical need already exists" do
        Need.create!(@atts)
        need = Need.new(@atts)

        refute need.save
        assert need.errors.full_messages.include?("This need already exists")
      end
    end

    context "creating revisions" do
      should "create an initial revision when given valid attributes" do
        need = create(:need, goal: "get a premises licence")

        assert_equal 1, need.revisions.count

        revision = need.revisions.first
        assert_equal "create", revision.action_type
        assert_equal "get a premises licence", revision.snapshot["goal"]
        assert_nil revision.author
      end

      should "store user information in the revision if provided" do
        need = build(:need, goal: "get a premises licence")
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
        need = build(:need, role: "")

        refute need.save
        refute need.save_as(name: "Winston Smith-Churchill", email: "winston@alphagov.co.uk")

        assert_equal 0, need.revisions.count
      end
    end
  end

  context "validations" do
    should validate_presence_of(:goal)

    context "associating needs with non-existent organisations" do
      setup do
        create(:organisation, name: "Home Office", slug: "home-office")
      end

      should_not allow_value(["does-not-exist"]).for(:organisation_ids)
      should_not allow_value(["home-office","does-not-exist"]).for(:organisation_ids)
    end

    should_not allow_value(-10).for(:yearly_user_contacts)

    should_not allow_value(-10).for(:yearly_site_views)

    should_not allow_value(-10).for(:yearly_need_views)

    should_not allow_value(-10).for(:yearly_searches)

    should allow_value(nil).for(:organisation_ids)
    should allow_value([]).for(:organisation_ids)
  end

  context "an existing need" do
    setup do
      create(:organisation, name: "Cabinet Office", slug: "cabinet-office")
      create(:organisation, name: "Ministry of Justice", slug: "ministry-of-justice")
    end

    should "return organisations" do
      need = create(:need, :organisation_ids => ["cabinet-office", "ministry-of-justice"])

      assert_equal 2, need.organisations.count
      assert_equal ["Cabinet Office", "Ministry of Justice"], need.organisations.map(&:name)
      assert_equal ["cabinet-office", "ministry-of-justice"], need.organisations.map(&:id)
    end

    should "return no organisations when no ids are present" do
      need = create(:need, :organisation_ids => nil)

      assert_equal 0, need.organisations.count
      assert_equal [], need.organisations.map(&:name)
      assert_equal [], need.organisations.map(&:id)
    end
  end

  context "updating a need" do
    setup do
      @need = create(:need, goal: "pay my car tax") # creates an initial revision

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

    should "update the status if a need is marked as invalid" do
      @need.update_attribute(:status, { description: NeedStatus::NOT_VALID, reasons: ["not in proposition"] })

      @need.reload

      assert_equal NeedStatus::NOT_VALID, @need.status.description
      assert_equal ["not in proposition"], @need.status.reasons
    end

    should "update the status if a need is marked as valid" do
      @need.update_attribute(:status, { description: NeedStatus::VALID, additional_comments: "really good need" })

      @need.reload

      assert_equal NeedStatus::VALID, @need.status.description
      assert_equal "really good need", @need.status.additional_comments
    end

    should "update the status if a need is marked as valid with conditions" do
      @need.update_attribute(:status, { description: NeedStatus::VALID_WITH_CONDITIONS, validation_conditions: "must improve a and b" })

      @need.reload

      assert_equal NeedStatus::VALID_WITH_CONDITIONS, @need.status.description
      assert_equal "must improve a and b", @need.status.validation_conditions
    end

    should "remove inconsistent fields from the need status when the status is updated" do
      @need.assign_attributes(status: { description: NeedStatus::NOT_VALID, reasons: ["not in proposition"] })
      @need.save

      @need.assign_attributes(status: { description: NeedStatus::PROPOSED })
      @need.save

      @need.reload

      assert_nil @need.status["reasons"]
    end
  end

  context "duplicated needs" do
    setup do
      @canonical_need = create(:need, goal: "pay my car tax")
      @duplicate_need = create(:need, goal: "tax my car")
      @triplicate_need = create(:need, goal: "Tax me motah")
    end

    should "have no duplicates by default" do
      refute @canonical_need.has_duplicates?
    end

    should "not be closed by default" do
      refute @canonical_need.closed?
    end

    context "duplicate needs" do
      should "be able to set a need as a duplicate" do
        set_duplicate(@duplicate_need, @canonical_need.need_id)
        @duplicate_need.reload

        assert_equal(@canonical_need.need_id, @duplicate_need.duplicate_of)
      end

      should "be closed once it is closed" do
        set_duplicate(@duplicate_need, @canonical_need.need_id)
        @duplicate_need.reload

        assert @duplicate_need.closed?
      end

      should "be invalid if given an incorrect need id" do
        set_duplicate(@duplicate_need, :incorrect_need_id)

        refute @duplicate_need.valid?
        assert @duplicate_need.errors.has_key?(:duplicate_of)
      end

      should "be invalid if given its own need id" do
        set_duplicate(@duplicate_need, @duplicate_need.need_id)

        refute @duplicate_need.valid?
        assert @duplicate_need.errors.has_key?(:duplicate_of)
      end

      should "be invalid if given a need id already marked as a duplicate" do
        set_duplicate(@duplicate_need, @canonical_need.need_id)
        @duplicate_need.reload
        set_duplicate(@triplicate_need, @duplicate_need.need_id)

        refute @triplicate_need.valid?
        assert @triplicate_need.errors.has_key?(:duplicate_of)
      end
    end

    context "canonical needs" do
      should "show it has a duplicate" do
        set_duplicate(@duplicate_need, @canonical_need.need_id)
        @canonical_need.reload

        assert @canonical_need.has_duplicates?
      end

      should "show it has multiple duplicates" do
        set_duplicate(@duplicate_need, @canonical_need.need_id)
        set_duplicate(@triplicate_need, @canonical_need.need_id)
        @canonical_need.reload

        assert @canonical_need.has_duplicates?
      end

      should "not allow duplicate chains" do
        set_duplicate(@triplicate_need, @duplicate_need.need_id)
        set_duplicate(@duplicate_need, @canonical_need.need_id)

        refute @duplicate_need.valid?
        assert @duplicate_need.errors.has_key?(:duplicate_of)
      end
    end

    context "reopening needs" do
      setup do
        set_duplicate(@duplicate_need, @canonical_need.need_id)
        @duplicate_need.reload
      end

      should "no longer be closed" do
        reopen(@duplicate_need)
        refute @duplicate_need.closed?
      end

      should "not have duplicate_of set" do
        reopen(@duplicate_need)
        assert_nil @duplicate_need.duplicate_of
      end

      should "mark the canonical need as having no duplicates" do
        reopen(@duplicate_need)
        refute @canonical_need.has_duplicates?
      end
    end
  end
end
