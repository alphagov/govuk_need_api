require "search/indexer"

namespace :search do
  desc "Index all needs"
  task :index_needs => :environment do
    begin
      puts "Indexing #{Need.all.count} needs..."
      Need.all.each do |need|
        GovukNeedApi.indexer.index(IndexableNeed.new(need))
      end
      puts "Done."
    rescue Search::Indexer::IndexingFailed => e
      puts "Failed to index need #{e.need_id}"
      puts "Document body: #{e.document.present}" if e.document
      puts "Exception: #{e.cause.inspect}" if e.cause
      raise "Indexing failed"
    end
  end

  desc "Create the index if it doesn't exist, or update if it does"
  task :ensure_index => :environment do
    index_config = GovukNeedApi.index_config

    unless index_config.index_exists?
      puts "Creating index"
      index_config.create_index
    end
    puts "Setting mappings"
    index_config.put_mappings
  end

  desc "Delete the index, if it exists"
  task :delete_index => :environment do
    index_config = GovukNeedApi.index_config
    if index_config.index_exists?
      puts "Deleting index"
      index_config.delete_index
    end
  end

  desc "Delete and re-create the index"
  task :blat_index => [:delete_index, :ensure_index]

  desc "Recreate the index and reindex all the needs"
  task :reset => [:blat_index, :index_needs]
end
