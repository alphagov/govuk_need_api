require_relative '../integration_test_helper'

class ClosingNeedsTest < ActionDispatch::IntegrationTest

  setup do
    login_as_stub_user
    @main_need = FactoryGirl.create(:need, role: "parent",
                                           goal: "find out school holiday dates for my local school",
                                           benefit: "I can plan around my child's education")
    @duplicate = FactoryGirl.create(:need, role: "grand-parent",
                                           goal: "find out school holiday dates for my local school",
                                           benefit: "I can plan around my grandchild's education")
    @author = {
      author: {
        name: "Winston Smith-Churchill",
        email: "winston@alphagov.co.uk"
      }
    }

    use_test_index
  end

  teardown do
    delete_test_index
  end

  should "404 if the need doesn't exist" do
    put("/needs/31415926536/closed",
        @author.merge(duplicate_of: @main_need.need_id))
    assert_equal 404, last_response.status
  end

  should "422 if the duplicate need id isn't valid" do
    put("/needs/#{@duplicate.need_id}/closed",
        @author.merge(duplicate_of: @duplicate.need_id))
    assert_equal 422, last_response.status
  end

  should "mark a need as a duplicate of another need" do
    put("/needs/#{@duplicate.need_id}/closed",
        @author.merge(duplicate_of: @main_need.need_id))

    assert [200, 204].include?(last_response.status)

    @duplicate.reload

    assert_equal @main_need.need_id, @duplicate.duplicate_of
  end
end
