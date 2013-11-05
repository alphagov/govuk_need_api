class NeedRevisionPresenter
  def initialize(revision, previous_revision)
    @revision = revision
    @previous_revision = previous_revision
  end

  def present
    {
      action_type: @revision.action_type,
      author: @revision.author,
      changes: @revision.changes_with(@previous_revision),
      created_at: @revision.created_at
    }
  end
end
