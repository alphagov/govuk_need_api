require 'delegate'

class NeedDecorator < SimpleDelegator

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
