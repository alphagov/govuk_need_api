class ReallyAddContentIdsToNeeds < Mongoid::Migration[4.2]
  def self.up
    Need.all.each do |n|
      n.save
    end
  end
end
