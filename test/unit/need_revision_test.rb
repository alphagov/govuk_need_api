require_relative '../test_helper'

class NeedRevisionTest < ActiveSupport::TestCase

  context "creating a revision" do
    setup do
      @atts = { action_type: "create", snapshot: { goal: "find my local park" }, author: { name: "Testy McTest", email: "test@alphagov.co.uk" } }
    end

    should "be created given valid attributes" do
      revision = NeedRevision.new(@atts)

      assert revision.valid?
      assert revision.save

      revision.reload

      assert_equal "create", revision.action_type
      assert_equal "find my local park", revision.snapshot["goal"]
      assert_equal "Testy McTest", revision.author["name"]
      assert_equal "test@alphagov.co.uk", revision.author["email"]
    end

    should "store the timestamp of the action" do
      revision = NeedRevision.create(@atts)

      assert_equal Time.now.to_s, revision.created_at.to_s
    end

    should "be invalid if the action type is not 'create' or 'update'" do
      revision = NeedRevision.new(@atts.merge(action_type: "replace"))

      refute revision.valid?
      assert revision.errors.has_key?(:action_type)
    end

    should "be invalid if the snapshot is nil" do
      revision = NeedRevision.new(@atts.merge(snapshot: nil))

      refute revision.valid?
      assert revision.errors.has_key?(:snapshot)
    end

    should "clean up the snapshot data" do
      snapshot = {
        "_id" => "100001",
        "need_id" => "100001",
        "role" => "user",
        "goal" => "find out when the clocks change",
        "benefit" => "i know when to change my clocks"
      }

      revision = NeedRevision.new(@atts.merge(snapshot: snapshot))
      revision.save

      revision.reload

      assert_equal ["role", "goal", "benefit"], revision.snapshot.keys
    end
  end

end
