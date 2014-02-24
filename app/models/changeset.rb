# Changset wraps the current and the previous Revisions
class Changeset

  attr_reader :current, :previous
  attr_reader :notes

  def initialize(current, previous, notes=[])
    @current = current
    @previous = previous
    @notes = notes
  end

  # This method returns the changes between the current revision and its
  # previous revision as a hash of arrays. Each array contains the previous value,
  # followed by the value for the current revision. For example:
  #
  #   {
  #     :role => [ "driver", "vehicle owner" ],
  #     :goal => [ "Pay my car tax", nil ],
  #     :benefit => [ nil, "I can drive my car" ],
  #   }
  #
  def changes
    snapshots = [ previous_snapshot, current.snapshot ]

    changed_keys.inject({}) { |changes, key|
      changes.merge(key => snapshots.map {|snapshot| snapshot[key] })
    }
  end

  private

  def changed_keys
    (current.snapshot.keys | previous_snapshot.keys).reject { |key|
      current.snapshot[key] == previous_snapshot[key]
    }
  end

  def previous_snapshot
    previous.present? ? previous.snapshot : { }
  end
end
