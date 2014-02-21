class ChangesetPresenter
  def initialize(changeset)
    @changeset = changeset
  end

  def present
    {
      action_type: @changeset.current.action_type,
      author: @changeset.current.author,
      changes: @changeset.changes,
      created_at: @changeset.current.created_at,
      notes: @changeset.notes.map { |n|
        {
          text: n.text,
          author: n.author,
          created_at: n.created_at
        }
      }
    }
  end
end
