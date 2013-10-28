require 'delegate'

class SnapshotRevisionDecorator < SimpleDelegator

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
    snapshots = [ previous_revision.snapshot, revision.snapshot ]

    changed_keys(previous_revision).inject({}) { |changes, key|
      changes.merge(key => snapshots.map {|snapshot| snapshot[key] })
    }
  end

  def changed_keys(previous_revision)
    (revision.snapshot.keys | previous_revision.snapshot.keys).reject { |key|
      revision.snapshot[key] == previous_revision.snapshot[key]
    }
  end

  private

  def revision
    __getobj__
  end

end
