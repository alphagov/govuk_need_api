require_relative '../../test_helper'

class OrganisationResultSetPresenterTest < ActiveSupport::TestCase

  setup do
    @organisations = [
      OpenStruct.new(id: "ministry-of-joy",    name: "Ministry of Joy",    slug: "ministry-of-joy"),
      OpenStruct.new(id: "ministry-of-plenty", name: "Ministry of Plenty", slug: "ministry-of-plenty"),
      OpenStruct.new(id: "ministry-of-peace",  name: "Ministry of Peace",  slug: "ministry-of-peace")
    ]
    @presenter = OrganisationResultSetPresenter.new(@organisations)
  end

  should "return all the organisations and status" do
    response = @presenter.as_json

    assert_equal "ok", response[:_response_info][:status]
    assert_equal 3, response[:organisations].size

    assert_equal "ministry-of-joy", response[:organisations][0][:id]
    assert_equal "Ministry of Joy", response[:organisations][0][:name]
    assert_equal "ministry-of-plenty", response[:organisations][1][:id]
    assert_equal "Ministry of Plenty", response[:organisations][1][:name]
    assert_equal "ministry-of-peace", response[:organisations][2][:id]
    assert_equal "Ministry of Peace", response[:organisations][2][:name]
  end
end
