class ChangesetPresenter
  def initialize(changeset)
    @changeset = changeset
  end

  def present
    {
      action_type: @changeset.action_type,
      author: @changeset.author,
      changes: @changeset.changes,
      created_at: @changeset.created_at
    }
  end
end
