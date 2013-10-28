require_relative '../../test_helper'

class SnapshotRevisionDecoratorTest < ActiveSupport::TestCase

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
    @decorator = SnapshotRevisionDecorator.new(@revision)
  end

  should "delegate methods to the provided revision" do
    assert_equal "Winston Smith-Churchill", @decorator.author[:name]
    assert_equal Time.parse("2013-10-01 10:00:00"), @decorator.created_at
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
        goal: [ "get a tax disc", "pay my car tax" ],
        benefit: [ "I can drive my car for a year", "I can drive my car" ]
      }

      changes = @decorator.changes_with previous_revision

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
        benefit: [ nil, "I can drive my car" ]
      }
      changes = @decorator.changes_with previous_revision

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
        justification: [[ "Only government does this" ], nil ]
      }
      changes = @decorator.changes_with previous_revision

      assert_equal expected_changes, changes
    end
  end
end
