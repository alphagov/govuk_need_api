class AddStatusToNeeds < Mongoid::Migration
  def self.up
    Need.all.each do |n|
      unless n.status.present?
        if n.in_scope.nil?
          n.status = NeedStatus.new(description: NeedStatus::PROPOSED)
        elsif n.in_scope == false
          n.status = NeedStatus.new(description: "out of scope", reason: n.out_of_scope_reason)
        else
          raise "Unexpected 'in_scope' value: #{n.in_scope.inspect} for #{n.inspect}"
        end
        n.save_as(name: "Need Importer")
      end
    end
  end
end
