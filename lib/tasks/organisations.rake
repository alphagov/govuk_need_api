require 'organisation_importer'

namespace :organisations do
  desc "Import organisations from the Organisations API"
  task :import => :environment do
    DistributedLock.new('organisations_import').lock do
      OrganisationImporter.new.run
    end
  end
end
