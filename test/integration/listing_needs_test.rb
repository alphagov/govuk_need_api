require_relative '../integration_test_helper'

class ListingNeedsTest < ActionDispatch::IntegrationTest

  setup do
    login_as_stub_user
  end

  context "listing needs without pagination" do
    setup do
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

      assert_equal ["car owner", "jobseeker", "student"], results.map{|n| n["role"] }.sort
      assert_equal ["apply for student finance", "renew my car tax", "search for jobs"], results.map{|n| n["goal"] }.sort
      assert_equal ["I can drive my car for another year", "I can get into work", "I can get the money I need to go to university"], results.map{|n| n["benefit"] }.sort
      assert_equal [1, 1, 2], results.map{|n| n["organisations"].size }.sort

      assert_equal "hm-treasury", results[0]["organisations"][0]["id"]
      assert_equal "HM Treasury", results[0]["organisations"][0]["name"]
    end

    context "filtering needs by organisation" do
      should "return the needs required by that organisation" do
        get "/needs?organisation_id=hm-treasury"
        body = JSON.parse(last_response.body)

        assert_equal 200, last_response.status
        assert_equal "ok", body["_response_info"]["status"]
        assert_equal 2, body["results"].size
        assert_equal ["car owner", "jobseeker"], body["results"].map{|n| n["role"] }.sort
        assert_equal ["renew my car tax", "search for jobs"], body["results"].map{|n| n["goal"] }.sort
        assert_equal ["I can drive my car for another year", "I can get into work"], body["results"].map{|n| n["benefit"] }.sort
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

  context "paginating needs" do
    should "return a maximum of fifty needs per page" do
      FactoryGirl.create_list(:need, 75)

      get "/needs"

      body = JSON.parse(last_response.body)

      assert_equal 50, body["results"].size

      assert_equal 100075, body["results"].first["id"]
      assert_equal 100026, body["results"].last["id"]
    end

    should "return the next page of needs" do
      FactoryGirl.create_list(:need, 75)

      get "/needs?page=2"

      body = JSON.parse(last_response.body)

      assert_equal 25, body["results"].size

      assert_equal 100025, body["results"].first["id"]
      assert_equal 100001, body["results"].last["id"]
    end

    context "next and previous links" do
      setup do
        FactoryGirl.create_list(:need, 101)
      end

      should "include information about the next and previous pages" do
        get "/needs?page=2"

        body = JSON.parse(last_response.body)
        assert_equal "ok", body["_response_info"]["status"]

        links = body["_response_info"]["links"]

        assert_equal 3, links.size

        assert_equal "http://example.org/needs?page=1", links[0]["href"]
        assert_equal "previous", links[0]["rel"]

        assert_equal "http://example.org/needs?page=3", links[1]["href"]
        assert_equal "next", links[1]["rel"]

        assert_equal "http://example.org/needs?page=2", links[2]["href"]
        assert_equal "self", links[2]["rel"]
      end

      should "not display the previous link on the first page" do
        get "/needs?page=1"

        body = JSON.parse(last_response.body)
        links = body["_response_info"]["links"]

        assert_equal ["next", "self"], links.map {|l| l['rel']}
      end

      should "not display the next link on the last page" do
        get "/needs?page=3"

        body = JSON.parse(last_response.body)
        links = body["_response_info"]["links"]

        assert_equal ["previous", "self"], links.map {|l| l['rel']}
      end
    end

    should "return information about the result set" do
      FactoryGirl.create_list(:need, 75)

      get "/needs?page=2"
      body = JSON.parse(last_response.body)

      assert_equal 75, body["total"]
      assert_equal 2, body["current_page"]
      assert_equal 2, body["pages"]
      assert_equal 51, body["start_index"]
      assert_equal 25, body["page_size"]
    end
  end
end
