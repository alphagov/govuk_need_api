class RemoveAppointedPersonForEnglandAndWalesOrganisation < Mongoid::Migration
  def self.up
    organisation = Organisation.where(_id: 'appointed-person-for-england-and-wales-under-the-proceeds-of-crime-act-2002').first
    if organisation.present?
      Need.where(organisation_ids: organisation.id).each do |need|
        print "#{need.need_id}: "
        need.organisation_ids = (need.organisation_ids - [organisation.id])

        if need.save
          print "Removed"
        else
          print "Error\n"
          print need.errors.full_messages.join("\n\t\t")
        end
        print "\n"
        # NOTE: this was needed at the time this migration was written
        # but this class has since been removed (we use mongo fulltext
        # instead of needing elasticsearch)
        # GovukNeedApi.indexer.index(Search::IndexableNeed.new(need))
      end

      organisation.destroy
    end
  end

  def self.down
    # This org was created in error, there's no need for a down to re-instate it
  end
end
