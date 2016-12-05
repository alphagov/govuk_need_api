class AddContentIdsToNeeds < Mongoid::Migration
  def self.up
    Need.all.each do |n|
      unless n.content_id.present?
        n.content_id = SecureRandom.uuid
        puts "Set content_id #{n.content_id} for #{n.id}."
        n.save
      end
    end
  end
end
