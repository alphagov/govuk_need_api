require_relative '../../test_helper'

class ChangesetTest < ActiveSupport::TestCase
  setup do
    @revision = OpenStruct.new(
      snapshot: {
        role: "car owner",
        goal: "pay my car tax",
        benefit: "I can drive my car"
      },
      author: {
        name: "Winston Smith-Churchill"
      },
      created_at: Time.parse("2013-10-01 10:00:00")
    )
  end

  should "delegate methods to the provided revision" do
    change = Changeset.new(@revision, nil)
    assert_equal "Winston Smith-Churchill", change.current.author[:name]
    assert_equal Time.parse("2013-10-01 10:00:00"), change.current.created_at
  end

  should "attach notes to a revision" do
    notes = [
      {
        text: "test",
        author: {
          name: "Winston Smith-Churchill"
        },
        created_at: Time.parse("2013-10-02 10:00:00")
      }
    ]
    change = Changeset.new(@revision, nil, notes)
    assert_equal "test", change.notes[0][:text]
    assert_equal Time.parse("2013-10-02 10:00:00"), change.notes[0][:created_at]
    assert_equal "Winston Smith-Churchill", change.notes[0][:author][:name]
  end

  context "calculating the changes with a previous revision" do
    should "include changes in values for existing keys" do
      previous_revision = OpenStruct.new(
        snapshot: {
          role: "car owner",
          goal: "get a tax disc",
          benefit: "I can drive my car for a year"
        }
      )
      expected_changes = {
        goal: ["get a tax disc", "pay my car tax"],
        benefit: ["I can drive my car for a year", "I can drive my car"]
      }

      changes = Changeset.new(@revision, previous_revision).changes

      assert_equal expected_changes, changes
    end

    should "include keys added in the new revision" do
      previous_revision = OpenStruct.new(
        snapshot: {
          role: "car owner",
          goal: "pay my car tax"
        }
      )
      expected_changes = {
        benefit: [nil, "I can drive my car"]
      }
      changes = Changeset.new(@revision, previous_revision).changes

      assert_equal expected_changes, changes
    end

    should "include keys removed in the new revision" do
      previous_revision = OpenStruct.new(
        snapshot: {
          role: "car owner",
          goal: "pay my car tax",
          benefit: "I can drive my car",
          justification: ["Only government does this"]
        }
      )
      expected_changes = {
        justification: [["Only government does this"], nil]
      }
      changes = Changeset.new(@revision, previous_revision).changes

      assert_equal expected_changes, changes
    end

    should "return all fields when previous edition is nil" do
      expected_changes = {
        role: [nil, "car owner"],
        goal: [nil, "pay my car tax"],
        benefit: [nil, "I can drive my car"]
      }
      changes = Changeset.new(@revision, nil).changes

      assert_equal expected_changes, changes
    end
  end
end
