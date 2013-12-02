class TransformFieldsFromMonthlyToYearly < Mongoid::Migration
  def self.up
    modify("monthly_","yearly_", -> x { x * 12 })
  end

  def self.down
    modify("yearly_","monthly_", -> x { x / 12 })
  end

  def self.modify(old_prefix, new_prefix, operation)
    collection = Need.db.collection("needs")

    ["site_views",
     "need_views",
     "searches",
     "user_contacts"
    ].each do |name|

      old_name = "#{old_prefix}#{name}"
      new_name = "#{new_prefix}#{name}"

      matching_records = collection.find({}, :fields => [old_name])
      matching_records.each do |record|

        new_value = operation.call(record[old_name])

        collection.update({"_id" => record["_id"]},
                          {"$set" => { new_name => new_value }})
        collection.update({"_id" => record["_id"]},
                          {"$unset" => { old_name => 1 }})
      end
    end

    # We want revision history of the changes.
    Need.all.each do |n|
      n.save_as(:name => "Winston Smith-Churchill",
                :email => "winston@alphagov.co.uk",
                :uid => nil)
    end
  end
end
