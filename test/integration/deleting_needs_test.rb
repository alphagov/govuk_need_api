require_relative '../integration_test_helper'

class DeletingNeedsTest < ActionDispatch::IntegrationTest

  setup do
    login_as_stub_user
    @need = create(:need, need_id: 100001)
  end

  should "not allow deletion" do
    delete "/needs/100001"
    assert_equal 405, last_response.status
    assert_equal 1, Need.count
  end
end
