class RemoveNeedStatusReasonField < Mongoid::Migration[4.2]
  def self.up
    Need.all.each do |need|
      need.status.unset(:reason)
    end
  end

  def self.down
    Rails.logger.warn("Cannot reinstate the status reason field")
  end
end
