require 'delegate'

# Decorator for a need to allow us to construct a list of Change objects from
# the need's revisions.
class NeedWithChangesets < SimpleDelegator
  def changesets
    (need.revisions + [nil]).each_cons(2).map {|revision, previous|
      Changeset.new(revision, previous)
    }
  end

  private

  def need
    __getobj__
  end
end
