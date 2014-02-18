class AddOutOfScopeReason < Mongoid::Migration
  def self.up
    Need.all.each do |need|
      need.set(:out_of_scope_reason, nil)
    end
  end

  def self.down
    Need.all.each do |need|
      need.unset(:out_of_scope_reason)
    end
  end
end
