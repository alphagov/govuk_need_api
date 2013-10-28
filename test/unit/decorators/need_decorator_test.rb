require_relative '../../test_helper'

class NeedDecoratorTest < ActiveSupport::TestCase

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

    @decorator = NeedDecorator.new(@need)
  end

  should "return revisions in pairs" do
    revision_pairs = @decorator.revisions_with_changes

    expected = [
      [ "John", "Paul" ],
      [ "Paul", "Ringo" ],
      [ "Ringo", "George" ],
      [ "George", nil ]
    ]

    pairs = revision_pairs.map {|pair| pair.map {|revision| revision.author[:name] if revision.present? }}
    assert_equal expected, pairs
  end

  should "return the current revision as an instance of RevisionDecorator" do
    revision_pairs = @decorator.revisions_with_changes

    revision_pairs.each do |(revision,previous)|
      assert revision.is_a?(RevisionDecorator)
    end
  end

end
