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

    should "present the organisations" do
      stub_presenter = stub
      OrganisationResultSetPresenter.expects(:new)
        .with(@organisations)
        .returns(stub_presenter)
      stub_presenter.expects(:as_json).returns("foo")

      get :index

      assert response.body.include?("foo")
    end
  end

end
