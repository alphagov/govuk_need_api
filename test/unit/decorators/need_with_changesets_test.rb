require_relative '../../test_helper'

class NeedWithChangesetsTest < ActiveSupport::TestCase

  setup do
    @need = FactoryGirl.create(:need)

    @need.revisions.first.destroy # get rid of the first revision as its author is nil
    @need.reload

    @revisions = [
      FactoryGirl.create(:need_revision, need: @need, author: { name: "John" }, created_at: 1.hour.ago),
      FactoryGirl.create(:need_revision, need: @need, author: { name: "Paul" }, created_at: 2.hours.ago),
      FactoryGirl.create(:need_revision, need: @need, author: { name: "Ringo" }, created_at: 3.hours.ago),
      FactoryGirl.create(:need_revision, need: @need, author: { name: "George" }, created_at: 4.hours.ago, action_type: "create")
    ]

    @decorator = NeedWithChangesets.new(@need)
  end

  should "return a list of changesets" do
    changesets = @decorator.changesets

    assert changesets.all? { |c| c.respond_to? :changes }
  end

  should "pair revisions correctly" do
    expected_authors = [
      [ "John", "Paul" ],
      [ "Paul", "Ringo" ],
      [ "Ringo", "George" ],
      [ "George", nil ]
    ]
    assert_equal expected_authors, @decorator.changesets.map { |changeset|
      [
        changeset.current.author[:name],
        (changeset.previous.author[:name] if changeset.previous)
      ]
    }
  end
end
