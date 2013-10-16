require_relative '../integration_test_helper'

class RetrievingNeedsTest < ActionDispatch::IntegrationTest

  setup do
    login_as_stub_user

    FactoryGirl.create(:organisation, name: "Department for Work and Pensions", slug: "department-for-work-and-pensions")
    FactoryGirl.create(:organisation, name: "HM Treasury", slug: "hm-treasury")
  end

  context "listing all needs" do
    should "return basic information about all the needs" do
      FactoryGirl.create(:need, role: "car owner",
                                goal: "renew my car tax",
                                benefit: "I can drive my car for another year",
                                organisation_ids: ["hm-treasury"])
      FactoryGirl.create(:need, role: "student",
                                goal: "apply for student finance",
                                benefit: "I can get the money I need to go to university",
                                organisation_ids: ["department-for-work-and-pensions"])
      FactoryGirl.create(:need, role: "jobseeker",
                                goal: "search for jobs",
                                benefit: "I can get into work",
                                organisation_ids: ["department-for-work-and-pensions", "hm-treasury"])

      get "/needs"
      assert_equal 200, last_response.status

      body = JSON.parse(last_response.body)
      assert_equal "ok", body["_response_info"]["status"]

      assert_equal 3, body["results"].size

      assert_equal ["car owner", "student", "jobseeker"], body["results"].map{|n| n["role"] }
      assert_equal ["renew my car tax", "apply for student finance", "search for jobs"], body["results"].map{|n| n["goal"] }
      assert_equal ["I can drive my car for another year", "I can get the money I need to go to university", "I can get into work"], body["results"].map{|n| n["benefit"] }
      assert_equal [1, 1, 2], body["results"].map{|n| n["organisations"].size }

      assert_equal "hm-treasury", body["results"][0]["organisations"][0]["id"]
      assert_equal "HM Treasury", body["results"][0]["organisations"][0]["name"]
    end
  end
end
