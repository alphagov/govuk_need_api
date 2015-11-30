require_relative '../test_helper'

class OrganisationTest < ActiveSupport::TestCase
  context "creating an organisation" do
    setup do
      @atts = {
        name: "Ministry of Magic",
        slug: "ministry-of-magic",
        abbreviation: "MOM",
        govuk_status: "live",
        parent_ids: ["ministry-of-sleight-of-hand"],
        child_ids: ["ministry-for-creationism",
                    "ministry-for-astrology"]
      }
    end

    should "be created with valid attributes" do
      organisation = Organisation.new(@atts)

      assert organisation.valid?
      assert organisation.save!

      organisation.reload

      assert_equal "Ministry of Magic", organisation.name
      assert_equal "ministry-of-magic", organisation.slug
      assert_equal "ministry-of-magic", organisation._id
      assert_equal "MOM", organisation.abbreviation
      assert_equal "live", organisation.govuk_status
      assert_equal ["ministry-of-sleight-of-hand"], organisation.parent_ids
      assert_equal ["ministry-for-creationism", "ministry-for-astrology"], organisation.child_ids
    end

    should validate_presence_of(:name)
    should validate_presence_of(:slug)

    should "have a JSON representation" do
      expected_json = {
        "name" => "Ministry of Magic",
        "id" => "ministry-of-magic",
        "abbreviation" => "MOM",
        "govuk_status" => "live",
        "parent_ids" => ["ministry-of-sleight-of-hand"],
        "child_ids" => ["ministry-for-creationism", "ministry-for-astrology"],
      }

      assert_equal expected_json, Organisation.new(@atts).as_json
    end
  end
end
