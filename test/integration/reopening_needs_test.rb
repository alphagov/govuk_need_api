require_relative '../integration_test_helper'

class ReopeningNeedsTest < ActionDispatch::IntegrationTest
  setup do
    login_as_stub_user

    travel_to 2.seconds.ago do # Avoid race condition on creation timestamps
      @canonical_need = create(:need, role: "parent",
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

    travel_to 1.second.ago do
      put("/needs/#{@duplicate.need_id}/closed",
          @author.merge(duplicate_of: @canonical_need.need_id))
    end
  end

  should "no longer be closed" do
    delete("/needs/#{@duplicate.need_id}/closed", @author)
    assert [200, 204].include?(last_response.status)

    @duplicate.reload
    refute @duplicate.closed?
  end

  should "not be a duplicate of another need" do
    delete("/needs/#{@duplicate.need_id}/closed", @author)

    @duplicate.reload
    refute @duplicate.duplicate_of

    @canonical_need.reload
    refute @canonical_need.has_duplicates?
  end

  should "404 if the need doesn't exist" do
    delete("/needs/31415926536/closed", @author)
    assert_equal 404, last_response.status
  end

  should "422 if the author isn't present" do
    delete("/needs/#{@duplicate.need_id}/closed")
    assert_equal 422, last_response.status
  end

  should "have reopen as the action type in revision history" do
    delete("/needs/#{@duplicate.need_id}/closed", @author)

    @duplicate.reload
    revision = @duplicate.revisions[0]

    assert_equal "reopen", revision.action_type
    assert_equal "Winston Smith-Churchill", revision.author["name"]
    assert_equal "winston@alphagov.co.uk", revision.author["email"]
  end
end
