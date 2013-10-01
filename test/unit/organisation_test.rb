require_relative '../test_helper'

class OrganisationTest < ActiveSupport::TestCase

  context "creating an organisation" do
    setup do
      @atts = {
        name: "Ministry of Magic",
        slug: "ministry-of-magic"
      }
    end

    should "be created with valid attributes" do
      organisation = Organisation.new(@atts)

      assert organisation.valid?
      assert organisation.save!

      organisation.reload

      assert_equal "Ministry of Magic", organisation.name
      assert_equal "ministry-of-magic", organisation.slug
    end

    should "not be valid without a name" do
      organisation = Organisation.new(@atts.merge(name: ""))

      refute organisation.valid?
      assert organisation.errors.has_key?(:name)
    end

    should "not be valid without a slug" do
      organisation = Organisation.new(@atts.merge(slug: ""))

      refute organisation.valid?
      assert organisation.errors.has_key?(:slug)
    end
  end

end
