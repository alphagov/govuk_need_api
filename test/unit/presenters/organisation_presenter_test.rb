require_relative '../../test_helper'

class OrganisationPresenterTest < ActiveSupport::TestCase

  setup do
    @organisation = OpenStruct.new(
      id: "ministry-of-joy",
      name: "Ministry of Joy",
      slug: "ministry-of-joy"
    )
    @presenter = OrganisationPresenter.new(@organisation)
  end

  should "return the basic attributes and status" do
    response = @presenter.as_json

    assert_equal "ok", response[:_response_info][:status]

    assert_equal "ministry-of-joy", response[:id]
    assert_equal "Ministry of Joy", response[:name]
  end

  should "return the basic attributes" do
    response = @presenter.present

    assert_equal "ministry-of-joy", response[:id]
    assert_equal "Ministry of Joy", response[:name]
  end
end
