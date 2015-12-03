require 'needs_importer'

namespace :needs do
  desc "Bulk import needs from a CSV file"
  task :import, [:path] => :environment do |_t, args|
    NeedsImporter.new(Rails.root.join(args[:path])).run
  end
end
