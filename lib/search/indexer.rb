module Search
  class Indexer
    def initialize(search_client, index_name, type)
      @client = search_client
      @index_name, @type = index_name, type
    end

    def index(document)
      @client.index(
        index: @index_name,
        type: @type,
        id: document.need_id,
        body: document.present
      )
    end
  end
end
