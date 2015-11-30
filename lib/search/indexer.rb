module Search
  class Indexer
    ERROR_CLASSES = [
      Elasticsearch::Transport::Transport::Error,
      Elasticsearch::Transport::Transport::ServerError,
      Elasticsearch::Transport::Transport::SnifferTimeoutError,
    ]

    class IndexingFailed < StandardError
      attr_reader :need_id, :document, :cause

      def initialize(need_id, document = nil, cause = nil)
        super("Indexing failed for need #{need_id}")
        @need_id = need_id
        @document = document
        @cause = cause
      end
    end

    def initialize(search_client, index_name, type)
      @client = search_client
      @index_name = index_name
      @type = type
    end

    def index(document)
      @client.index(
        index: @index_name,
        type: @type,
        id: document.need_id,
        body: document.present
      )
    rescue *ERROR_CLASSES => e
      raise IndexingFailed.new(document.need_id, document, e)
    end
  end
end
