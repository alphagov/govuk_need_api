require_relative '../integration_test_helper'

class ShowingNeedsTest < ActionDispatch::IntegrationTest

  setup do
    login_as_stub_user
  end

  context "retrieving a single need" do
    setup do
      FactoryGirl.create(:organisation, name: "Department for Work and Pensions", slug: "department-for-work-and-pensions")
      @need = FactoryGirl.create(:need, role: "parent",
                                        goal: "find out school holiday dates for my local school",
                                        benefit: "I can plan around my child's education",
                                        organisation_ids: ["department-for-work-and-pensions"],
                                        need_id: 100001)
    end

    should "return details about the need" do
      get "/needs/100001"
      assert_equal 200, last_response.status

      body = JSON.parse(last_response.body)
      assert_equal "ok", body["_response_info"]["status"]

      assert_equal 100001, body["id"]

      assert_equal "parent", body["role"]
      assert_equal "find out school holiday dates for my local school", body["goal"]
      assert_equal "I can plan around my child's education", body["benefit"]

      assert_equal ["department-for-work-and-pensions"], body["organisation_ids"]
      assert_equal 1, body["organisations"].size
      assert_equal "department-for-work-and-pensions", body["organisations"].first["id"]
      assert_equal "Department for Work and Pensions", body["organisations"].first["name"]
    end

    should "return a not found response" do
      get "/needs/42"
      assert_equal 404, last_response.status

      body = JSON.parse(last_response.body)
      assert_equal "not_found", body["_response_info"]["status"]
      assert body["error"].present?
    end
  end
end
