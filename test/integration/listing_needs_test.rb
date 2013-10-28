require_relative '../integration_test_helper'

class ListingNeedsTest < ActionDispatch::IntegrationTest

  setup do
    login_as_stub_user

    FactoryGirl.create(:organisation, name: "Department for Work and Pensions", slug: "department-for-work-and-pensions")
    FactoryGirl.create(:organisation, name: "HM Treasury", slug: "hm-treasury")

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

  end

  context "listing all needs" do
    should "return basic information about all the needs" do
      get "/needs"
      assert_equal 200, last_response.status

      body = JSON.parse(last_response.body)
      assert_equal "ok", body["_response_info"]["status"]

      # quick fix to sort results by the Need ID
      # remove once we have explicit sorting on needs
      #
      results = body["results"].sort_by{|r| r["id"] }

      assert_equal 3, results.size

      assert_equal ["car owner", "student", "jobseeker"], results.map{|n| n["role"] }
      assert_equal ["renew my car tax", "apply for student finance", "search for jobs"], results.map{|n| n["goal"] }
      assert_equal ["I can drive my car for another year", "I can get the money I need to go to university", "I can get into work"], results.map{|n| n["benefit"] }
      assert_equal [1, 1, 2], results.map{|n| n["organisations"].size }

      assert_equal "hm-treasury", results[0]["organisations"][0]["id"]
      assert_equal "HM Treasury", results[0]["organisations"][0]["name"]
    end
  end

  context "filtering needs by organisation" do
    should "return the needs required by that organisation" do
      get "/needs?organisation_id=hm-treasury"
      body = JSON.parse(last_response.body)

      assert_equal 200, last_response.status
      assert_equal "ok", body["_response_info"]["status"]
      assert_equal 2, body["results"].size
      assert_equal ["car owner", "jobseeker"], body["results"].map{|n| n["role"] }
      assert_equal ["renew my car tax", "search for jobs"], body["results"].map{|n| n["goal"] }
      assert_equal ["I can drive my car for another year", "I can get into work"], body["results"].map{|n| n["benefit"] }
    end

    should "return all needs if no organisation is given" do
      get "/needs?organisation_id="
      body = JSON.parse(last_response.body)

      assert_equal 200, last_response.status
      assert_equal "ok", body["_response_info"]["status"]
      assert_equal 3, body["results"].size
    end

    should "return no needs if the organisation has no needs" do
      get "/needs?organisation_id=department-of-justice"
      body = JSON.parse(last_response.body)

      assert_equal 200, last_response.status
      assert_equal "ok", body["_response_info"]["status"]
      assert_equal 0, body["results"].size
    end
  end
end
