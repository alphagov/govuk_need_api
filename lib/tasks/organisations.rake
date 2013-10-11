require 'organisation_importer'

namespace :organisations do
  task :import => :environment do
    importer = OrganisationImporter.new(Rails.root.join("data","organisations.csv"))
    importer.run
  end
end
