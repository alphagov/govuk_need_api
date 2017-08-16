class TransformFieldsFromMonthlyToYearly < Mongoid::Migration[4.2]
  def self.up
    modify("monthly_","yearly_", -> x { x * 12 })
  end

  def self.down
    modify("yearly_","monthly_", -> x { x / 12 })
  end

  def self.modify(old_prefix, new_prefix, operation)
    collection = Need.db.collection(Need.collection_name)

    ["site_views",
     "need_views",
     "searches",
     "user_contacts"
    ].each do |name|

      old_name = "#{old_prefix}#{name}"
      new_name = "#{new_prefix}#{name}"

      matching_records = collection.find({old_name => {"$exists" => 1}}, :fields => [old_name])
      matching_records.each do |record|

        new_value = operation.call(record[old_name]) unless record[old_name].nil?

        collection.update({"_id" => record["_id"]},
                          {"$set" => { new_name => new_value },
                           "$unset" => { old_name => 1 }
                          })
      end
    end

    # We want revision history of the changes.
    Need.all.each do |n|
      n.save_as(:name => "Data Migration",
                :email => "govuk-maslow@digital.cabinet-office.gov.uk",
                :uid => nil)
    end
  end
end
