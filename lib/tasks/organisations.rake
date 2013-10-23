require 'organisation_importer'

namespace :organisations do
  desc "Import organisations from the CSV file in `data`"
  task :import => :environment do
    importer = OrganisationImporter.new(Rails.root.join("data","organisations.csv"))
    importer.run
  end
end
