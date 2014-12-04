require_relative '../../test_helper'

class BasicNeedPresenterTest < ActiveSupport::TestCase

  setup do
    @need = OpenStruct.new(
      id: "blah-bson-id",
      need_id: 123456,
      role: "business owner",
      goal: "find out the VAT rate",
      benefit: "I can charge my customers the correct amount",
      met_when: [ "the user sees the current vat rate", "the api user can access the current vat rate" ],
      organisation_ids: [ "ministry-of-testing" ],
      organisations: [
        build(:organisation, name: "Ministry of Testing", slug: "ministry-of-testing")
      ],
      applies_to_all_organisations: true,
      duplicate_of: 100001,
      status: NeedStatus.new(description: NeedStatus::PROPOSED),
    )
    @presenter = BasicNeedPresenter.new(@need)
  end

  should "return a need as json" do
    response = @presenter.as_json

    assert_equal 123456, response[:id]

    assert_equal "business owner", response[:role]
    assert_equal "find out the VAT rate", response[:goal]
    assert_equal "I can charge my customers the correct amount", response[:benefit]

    assert_equal [ "the user sees the current vat rate",
      "the api user can access the current vat rate" ], response[:met_when]

    assert_equal ["ministry-of-testing"], response[:organisation_ids]

    assert_equal 1, response[:organisations].size
    assert_equal "Ministry of Testing", response[:organisations][0]["name"]
    assert_equal "ministry-of-testing", response[:organisations][0]["id"]

    assert_equal true, response[:applies_to_all_organisations]

    assert_equal 100001, response[:duplicate_of]

    assert_equal Hash["description" => NeedStatus::PROPOSED], response[:status]
  end

  context "for a need fetched from elastic search" do
    should "return a JSON representation for the status" do
      need = build(:need, status: { "description" => NeedStatus::PROPOSED })

      json = BasicNeedPresenter.new(need).as_json

      assert_equal Hash["description" => NeedStatus::PROPOSED], json[:status]
    end
  end
end
