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
      Timecop.freeze do
        revision = NeedRevision.create(@atts)

        assert_equal Time.now.to_s, revision.created_at.to_s
      end
    end

    should_not allow_value("replace").for(:action_type)

    should_not allow_value(nil).for(:snapshot)

    should "clean up the snapshot data" do
      snapshot = {
        "_id" => "100001",
        "need_id" => "100001",
        "role" => "user",
        "goal" => "find out when the clocks change",
        "benefit" => "i know when to change my clocks",
        "status" => {
          "_id" => OpenStruct.new(id: '12345'),
          "description"=>"proposed",
        },
      }

      revision = NeedRevision.new(@atts.merge(snapshot: snapshot))
      revision.save

      revision.reload

      assert_equal ["role", "goal", "benefit", "status"], revision.snapshot.keys
      assert_equal Hash["description" => "proposed"], revision.snapshot["status"]
    end
  end

end
