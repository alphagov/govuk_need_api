require_relative '../test_helper'

class NeedsControllerTest < ActionController::TestCase

  setup do
    login_as_stub_user
  end

  context "POST create" do
    context "given a valid need" do
      setup do
        @need = {
          role: "user",
          goal: "find my local council",
          benefit: "contact them about a local enquiry"
        }
      end

      should "persist the need" do
        post :create, need: @need

        need = Need.first

        assert_equal 1, Need.count
        assert_equal "user", need.role
        assert_equal "find my local council", need.goal
        assert_equal "contact them about a local enquiry", need.benefit
      end

      should "return a created status" do
        post :create, need: @need

        assert_response :created

        body = JSON.parse(response.body)
        assert_equal "created", body["_response_info"]["status"]
      end

      should "return details about the new need" do
        post :create, need: @need

        need = Need.first
        body = JSON.parse(response.body)

        assert_equal "http://test.host/needs/#{need.id}", body["id"]
        assert_equal "user", body["role"]
        assert_equal "find my local council", body["goal"]
        assert_equal "contact them about a local enquiry", body["benefit"]
      end
    end
  end

end
