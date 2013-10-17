require_relative '../../test_helper'

class NeedResultSetPresenterTest < ActiveSupport::TestCase

  class MockViewContext
    def need_url(need_id)
      "http://need-api.test.gov.uk/needs/#{need_id}"
    end
  end

  setup do
    @needs = [
      OpenStruct.new(
        id: 1,
        role: "business owner",
        goal: "find out the VAT rate",
        benefit: "I can charge my customers the correct amount",
        organisation_ids: [ "ministry-of-testing" ],
        organisations: [
          OpenStruct.new(id: "ministry-of-testing", name: "Ministry of Testing", slug: "ministry-of-testing")
        ]
      ),
      OpenStruct.new(
        id: 2,
        role: "car owner",
        goal: "renew my car tax",
        benefit: "I can drive my car for another year",
        organisation_ids: [ "ministry-of-testing" ],
        organisations: [
          OpenStruct.new(id: "ministry-of-testing", name: "Ministry of Testing", slug: "ministry-of-testing")
        ]
      )
    ]
    @view_context = MockViewContext.new
    @presenter = NeedResultSetPresenter.new(@needs, @view_context)
  end

  should "return a collection of needs as json" do
    response = @presenter.as_json

    assert_equal "ok", response[:_response_info][:status]
    assert_equal 2, response[:results].size

    assert_equal [1, 2], response[:results].map {|i| i[:id] }
    assert_equal ["business owner", "car owner"], response[:results].map {|i| i[:role] }
    assert_equal ["find out the VAT rate", "renew my car tax"], response[:results].map {|i| i[:goal] }
    assert_equal ["I can charge my customers the correct amount", "I can drive my car for another year"], response[:results].map {|i| i[:benefit] }

    assert_equal ["ministry-of-testing"], response[:results][0][:organisation_ids]

    assert_equal 1, response[:results][0][:organisations].size
    assert_equal "Ministry of Testing", response[:results][0][:organisations][0][:name]
    assert_equal "ministry-of-testing", response[:results][0][:organisations][0][:id]
  end
end
