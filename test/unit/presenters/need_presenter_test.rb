require_relative '../../test_helper'

class NeedPresenterTest < ActiveSupport::TestCase

  setup do
    @need = OpenStruct.new(
      id: "blah-bson-id",
      need_id: 123456,
      role: "business owner",
      goal: "find out the VAT rate",
      benefit: "I can charge my customers the correct amount",
      organisation_ids: [ "ministry-of-testing" ],
      organisations: [
        OpenStruct.new(id: "ministry-of-testing", name: "Ministry of Testing", slug: "ministry-of-testing")
      ],
      justifications: [ "legislation", "other" ],
      impact: "Noticed by an expert audience",
      met_when: [ "the user sees the current vat rate" ],
      monthly_user_contacts: 1000,
      monthly_site_views: 10000,
      monthly_need_views: 1000,
      monthly_searches: 2000,
      currently_met: false,
      other_evidence: "Other evidence",
      legislation: "link#1\nlink#2"
    )
    @presenter = NeedPresenter.new(@need)
  end

  should "return an need as json" do
    response = @presenter.as_json

    assert_equal "ok", response[:_response_info][:status]
    assert_equal 123456, response[:id]

    assert_equal "business owner", response[:role]
    assert_equal "find out the VAT rate", response[:goal]
    assert_equal "I can charge my customers the correct amount", response[:benefit]

    assert_equal ["ministry-of-testing"], response[:organisation_ids]

    assert_equal 1, response[:organisations].size
    assert_equal "Ministry of Testing", response[:organisations][0][:name]
    assert_equal "ministry-of-testing", response[:organisations][0][:id]

    assert_equal ["legislation", "other"], response[:justifications]
    assert_equal "Noticed by an expert audience", response[:impact]
    assert_equal ["the user sees the current vat rate"], response[:met_when]

    assert_equal 1000, response[:monthly_user_contacts]
    assert_equal 10000, response[:monthly_site_views]
    assert_equal 1000, response[:monthly_need_views]
    assert_equal 2000, response[:monthly_searches]
    assert_equal false, response[:currently_met]
    assert_equal "Other evidence", response[:other_evidence]
    assert_equal "link#1\nlink#2", response[:legislation]
  end

  should "return a custom status" do
    response = @presenter.as_json(status: "created")

    assert_equal "created", response[:_response_info][:status]
  end


end
