class RemoveCurrentlyMetField < Mongoid::Migration
  def self.up
    Need.all.each do |need|
      need.unset(:currently_met)
    end
  end

  def self.down
    Rails.logger.warn("Cannot reinstate the currently_met field")
  end
end
