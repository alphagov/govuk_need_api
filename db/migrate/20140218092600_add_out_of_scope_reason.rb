class AddOutOfScopeReason < Mongoid::Migration[4.2]
  def self.up
    Need.all.each do |need|
      value = need.in_scope == false ? "closed" : nil
      need.set(:out_of_scope_reason, value)
    end
  end

  def self.down
    Need.all.each do |need|
      need.unset(:out_of_scope_reason)
    end
  end
end
