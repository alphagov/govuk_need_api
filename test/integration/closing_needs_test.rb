require_relative '../integration_test_helper'

class ClosingNeedsTest < ActionDispatch::IntegrationTest

  setup do
    login_as_stub_user
    use_test_index
    Timecop.freeze(-2) do # Avoid race condition on creation timestamps
      @main_need = create(:need, role: "parent",
                                             goal: "find out school holiday dates for my local school",
                                             benefit: "I can plan around my child's education")
      @duplicate = create(:need, role: "grand-parent",
                                             goal: "find out school holiday dates for my local school",
                                             benefit: "I can plan around my grandchild's education")
      @author = {
        author: {
          name: "Winston Smith-Churchill",
          email: "winston@alphagov.co.uk"
        }
      }

    end
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

  should "have close as the action type in revision history" do
    put("/needs/#{@duplicate.need_id}/closed",
        @author.merge(duplicate_of: @main_need.need_id))

    @duplicate.reload
    revision = @duplicate.revisions[0]

    assert_equal "close", revision.action_type
    assert_equal "Winston Smith-Churchill", revision.author["name"]
    assert_equal "winston@alphagov.co.uk", revision.author["email"]
  end

  should "409 if the need is already closed" do
    put("/needs/#{@duplicate.need_id}/closed",
        @author.merge(duplicate_of: @main_need.need_id))
    assert [200, 204].include?(last_response.status)

    put("/needs/#{@duplicate.need_id}/closed",
        @author.merge(duplicate_of: @main_need.need_id))
    assert_equal 409, last_response.status
  end
end
