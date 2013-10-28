require 'delegate'

class RevisionDecorator < SimpleDelegator

  # This method returns the changes between the decorated revision and a given
  # previous revision as a hash of arrays. Each array contains the previous value,
  # followed by the current value for the decorated revision. For example:
  #
  #   {
  #     :role => [ "driver", "vehicle owner" ],
  #     :goal => [ "Pay my car tax", nil ],
  #     :benefit => [ nil, "I can drive my car" ],
  #   }
  #
  def changes_with(previous_revision)
    previous_snapshot = previous_revision.present? ? previous_revision.snapshot : { }
    snapshots = [ previous_snapshot, revision.snapshot ]

    changed_keys(previous_snapshot).inject({}) { |changes, key|
      changes.merge(key => snapshots.map {|snapshot| snapshot[key] })
    }
  end

  def changed_keys(previous_snapshot)
    (revision.snapshot.keys | previous_snapshot.keys).reject { |key|
      revision.snapshot[key] == previous_snapshot[key]
    }
  end

  private

  def revision
    __getobj__
  end

end
