class ChangesetPresenter
  def initialize(changeset)
    @changeset = changeset
  end

  def as_json
    {
      action_type: @changeset.current.action_type,
      author: @changeset.current.author,
      changes: @changeset.changes,
      created_at: @changeset.current.created_at,
      notes: @changeset.notes.map { |note|
        {
          text: note.text,
          author: note.author,
          created_at: note.created_at
        }
      }
    }
  end
end
