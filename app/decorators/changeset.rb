require 'delegate'

# Decorator on top of the Revision model, composing it with its previous
# revision so we can say what's changed.
class Changeset < SimpleDelegator

  attr_reader :previous

  def initialize(revision, previous)
    super(revision)
    @previous = previous
  end

  # This method returns the changes between the decorated revision and its
  # previous revision as a hash of arrays. Each array contains the previous value,
  # followed by the current value for the decorated revision. For example:
  #
  #   {
  #     :role => [ "driver", "vehicle owner" ],
  #     :goal => [ "Pay my car tax", nil ],
  #     :benefit => [ nil, "I can drive my car" ],
  #   }
  #
  def changes
    snapshots = [ previous_snapshot, revision.snapshot ]

    changed_keys.inject({}) { |changes, key|
      changes.merge(key => snapshots.map {|snapshot| snapshot[key] })
    }
  end

  private

  def changed_keys
    (revision.snapshot.keys | previous_snapshot.keys).reject { |key|
      revision.snapshot[key] == previous_snapshot[key]
    }
  end

  def previous_snapshot
    @previous.present? ? @previous.snapshot : { }
  end

  def revision
    __getobj__
  end

end
