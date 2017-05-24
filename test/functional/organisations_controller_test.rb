require_relative '../test_helper'

class OrganisationsControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
  end

  context "GET index" do
    setup do
      @organisations = [
        create(:organisation, name: "Department for Transport", slug: "department-for-transport"),
        create(:organisation, name: "Home Office", slug: "home-office"),
        create(:organisation, name: "Ministry of Justice", slug: "ministry-of-justice")
      ]
    end

    should "return a successful response" do
      get :index

      assert_response :success

      body = JSON.parse(response.body)
      assert_equal "ok", body["_response_info"]["status"]
    end

    should "present the organisations" do
      get :index

      body = JSON.parse(response.body)
      org_names = body["organisations"].map { |org| org["name"] }
      assert_equal ["Department for Transport", "Home Office", "Ministry of Justice"], org_names
    end
  end
end
