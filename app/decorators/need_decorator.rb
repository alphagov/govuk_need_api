require 'delegate'

class NeedDecorator < SimpleDelegator

  # Return all the revisions for the need as array pairs. Each pair contains a revision,
  # decorated with the RevisionDecorator, along with the previous revision. The previous
  # revision can be nil - for example if this is the first revision.
  #
  def revisions_with_changes
    (need.revisions + [nil]).each_cons(2).map {|action, previous|
      [ RevisionDecorator.new(action), previous ]
    }
  end

  private

  def need
    __getobj__
  end

end
