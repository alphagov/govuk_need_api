class ReallyAddContentIdsToNeeds < Mongoid::Migration
  def self.up
    Need.all.each do |n|
      n.save
    end
  end
end
