require "search/indexer"

namespace :search do
  desc "Index all needs"
  task :index => :environment do
    begin
      puts "Indexing #{Need.all.count} needs..."
      Need.all.each do |need|
        GovukNeedApi.indexer.index(IndexableNeed.new(need))
      end
      puts "Done."
    rescue Search::Indexer::IndexingFailed => e
      puts "Failed to index need #{e.need_id}"
      puts "Document body: #{e.document.present}"
      puts "Exception: #{e.cause.inspect}"
      exit(1)
    end
  end
end
