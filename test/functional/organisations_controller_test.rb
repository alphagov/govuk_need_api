require_relative '../test_helper'

class OrganisationsControllerTest < ActionController::TestCase

  setup do
    login_as_stub_user
  end

  context "GET index" do
    setup do
      @organisations = [
        FactoryGirl.create(:organisation, name: "Department for Transport", slug: "department-for-transport"),
        FactoryGirl.create(:organisation, name: "Home Office", slug: "home-office"),
        FactoryGirl.create(:organisation, name: "Ministry of Justice", slug: "ministry-of-justice")
      ]
    end

    should "return a successful response" do
      get :index

      assert_response :success

      body = JSON.parse(response.body)
      assert_equal "ok", body["_response_info"]["status"]
    end

    should "return a list of all organisations" do
      get :index

      body = JSON.parse(response.body)
      assert_equal 3, body["organisations"].size

      assert_equal "department-for-transport", body["organisations"][0]["id"]
      assert_equal "Department for Transport", body["organisations"][0]["name"]

      assert_equal "home-office", body["organisations"][1]["id"]
      assert_equal "Home Office", body["organisations"][1]["name"]

      assert_equal "ministry-of-justice", body["organisations"][2]["id"]
      assert_equal "Ministry of Justice", body["organisations"][2]["name"]
    end
  end

end
