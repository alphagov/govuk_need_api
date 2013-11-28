require "search/indexer"

@logger = Logger.new(ENV["RAILS_ENV"] == "test" ? "/dev/null" : STDOUT)

namespace :search do
  desc "Index all needs"
  task :index_needs => :environment do
    begin
      @logger.info "Indexing #{Need.all.count} needs..."
      Need.all.each do |need|
        GovukNeedApi.indexer.index(IndexableNeed.new(need))
      end
      @logger.info "Done."
    rescue Search::Indexer::IndexingFailed => e
      @logger.error "Failed to index need #{e.need_id}"
      @logger.error "Document body: #{e.document.present}" if e.document
      @logger.error "Exception: #{e.cause.inspect}" if e.cause
      raise "Indexing failed"
    end
  end

  desc "Create the index if it doesn't exist, or update if it does"
  task :ensure_index => :environment do
    index_config = GovukNeedApi.index_config

    unless index_config.index_exists?
      @logger.info "Creating index"
      index_config.create_index
    end
    @logger.info "Setting mappings"
    index_config.put_mappings
  end

  desc "Delete the index, if it exists"
  task :delete_index => :environment do
    index_config = GovukNeedApi.index_config
    if index_config.index_exists?
      @logger.info "Deleting index"
      index_config.delete_index
    end
  end

  desc "Delete and re-create the index"
  task :blat_index => [:delete_index, :ensure_index]

  desc "Recreate the index and reindex all the needs"
  task :reset => [:blat_index, :index_needs]
end
