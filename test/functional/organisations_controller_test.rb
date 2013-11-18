require_relative '../test_helper'

class OrganisationsControllerTest < ActionController::TestCase

  setup do
    login_as_stub_user
  end

  context "GET index" do
    setup do
      FactoryGirl.create(:organisation, name: "Department for Transport", slug: "department-for-transport")
      FactoryGirl.create(:organisation, name: "Home Office", slug: "home-office")
      FactoryGirl.create(:organisation, name: "Ministry of Justice", slug: "ministry-of-justice")
    end

    should "return a successful response" do
      get :index

      assert_response :success

      body = JSON.parse(response.body)
      assert_equal "ok", body["_response_info"]["status"]
    end

    should "present the organisations using as_json" do
      result_set_presenter = OpenStruct.new(:as_json => "foo")
      OrganisationResultSetPresenter.expects(:new).returns(result_set_presenter)

      result_set_presenter.expects(:as_json)

      get :index
    end
  end

end
