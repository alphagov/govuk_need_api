class ChangeOutOfScopeStatusToNotValidStatus < Mongoid::Migration
  def self.up
    Need.all.each do |n|
      if n.status.description == "out of scope"
        n.status.description = NeedStatus::NOT_VALID
        n.status.reasons = [ "the need is not in scope for GOV.UK because it's #{n.status.reason}" ]
        n.status.reason = nil
        n.save_as(name: "Data Migration")
      end
    end
  end
end
