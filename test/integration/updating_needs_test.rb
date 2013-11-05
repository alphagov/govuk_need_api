require_relative '../integration_test_helper'

class UpdatingNeedsTest < ActionDispatch::IntegrationTest

  setup do
    login_as_stub_user
    @need = FactoryGirl.create(:need, role: "parent",
                                      goal: "find out school holiday dates for my local school",
                                      benefit: "I can plan around my child's education")
    @author = {
      author: {
        name: "Winston Smith-Churchill",
        email: "winston@alphagov.co.uk"
      }
    }
  end

  should "404 if the need doesn't exist" do
    put "/needs/31415926536", @author.merge(role: "numerical constant")
    assert_equal 404, last_response.status
  end

  should "update a need and create a revision with the author details" do
    put "/needs/#{@need.need_id}", @author.merge(role: "grandparent")

    assert [200, 204].include?(last_response.status)

    @need.reload

    assert_equal "grandparent", @need.role
    assert_equal "find out school holiday dates for my local school", @need.goal
    assert_equal "I can plan around my child's education", @need.benefit

    revision = @need.revisions.where(action_type: "update").first
    assert_equal "Winston Smith-Churchill", revision.author["name"]
    assert_equal "winston@alphagov.co.uk", revision.author["email"]
  end

  should "refuse invalid attributes" do
    put "/needs/#{@need.id}", @author.merge(role: "")
    assert_equal 422, last_response.status
    @need.reload
    assert_equal "parent", @need.role
  end

  should "refuse to update the need ID" do
    put "/needs/#{@need.need_id}", @author.merge(need_id: 57)
    assert_equal 422, last_response.status

    assert_equal [@need.need_id], Need.all.to_a.map(&:need_id)
  end

  should "refuse to update the need ID to a non-number" do
    put "/needs/#{@need.need_id}", @author.merge(need_id: "walrus")
    assert_equal 422, last_response.status

    assert_equal [@need.need_id], Need.all.to_a.map(&:need_id)
  end

  should "permit need IDs that are the same as the current value" do
    put "/needs/#{@need.need_id}", @author.merge(need_id: @need.need_id)
    assert [200, 204].include?(last_response.status)

    assert_equal [@need.need_id], Need.all.to_a.map(&:need_id)
  end

  should "return errors given no author details" do
    put "/needs/#{@need.need_id}", role: "user", author: nil
    assert_equal 422, last_response.status

    body = JSON.parse(last_response.body)
    assert_equal "author_not_provided", body["_response_info"]["status"]

    assert_equal "Author details must be provided", body["errors"].first
  end
end
