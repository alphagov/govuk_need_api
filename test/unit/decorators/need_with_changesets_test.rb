require_relative '../../test_helper'

class NeedWithChangesetsTest < ActiveSupport::TestCase
  setup do
    @need = create(:need)

    @need.revisions.first.destroy # get rid of the first revision as its author is nil
    @need.reload

    @revisions = [
      create(:need_revision, need: @need, author: { name: "John" }, created_at: 1.hour.ago),
      create(:need_revision, need: @need, author: { name: "Paul" }, created_at: 2.hours.ago),
      create(:need_revision, need: @need, author: { name: "Ringo" }, created_at: 3.hours.ago),
      create(:need_revision, need: @need, author: { name: "George" }, created_at: 4.hours.ago, action_type: "create")
    ]

    @decorator = NeedWithChangesets.new(@need)
  end

  should "return a list of changesets" do
    changesets = @decorator.changesets

    assert changesets.all? { |c| c.respond_to? :changes }
  end

  should "pair revisions correctly" do
    expected_authors = [
      %w(John Paul),
      %w(Paul Ringo),
      %w(Ringo George),
      ["George", nil]
    ]
    assert_equal expected_authors, @decorator.changesets.map { |changeset|
      [
        changeset.current.author[:name],
        (changeset.previous.author[:name] if changeset.previous)
      ]
    }
  end

  should "fetch notes" do
    @revisions.map { |revision|
      { revision: revision.id }
    }.each do |search_term|
      Note.expects(:where).with(search_term)
    end
    @decorator.changesets
  end
end
