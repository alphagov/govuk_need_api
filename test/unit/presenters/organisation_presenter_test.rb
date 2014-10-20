require_relative '../../test_helper'

class OrganisationPresenterTest < ActiveSupport::TestCase

  setup do
    @organisation = OpenStruct.new(
      id: "ministry-of-joy",
      name: "Ministry of Joy",
      slug: "ministry-of-joy",
      govuk_status: "live",
      abbreviation: "MOJ",
      parent_ids: ["ministry-of-amusement"],
      child_ids: ["ministry-of-elation","ministry-of-revelry"]
    )
    @presenter = OrganisationPresenter.new(@organisation)
  end

  should "return the basic attributes" do
    response = @presenter.present

    assert_equal "ministry-of-joy", response[:id]
    assert_equal "Ministry of Joy", response[:name]
    assert_equal "live", response[:govuk_status]
    assert_equal "MOJ", response[:abbreviation]
    assert_equal ["ministry-of-amusement"], response[:parent_ids]
    assert_equal ["ministry-of-elation","ministry-of-revelry"], response[:child_ids]
  end
end
