module Search
  class Searcher
    def initialize(search_client, index_name, type)
      @client = search_client
      @index_name, @type = index_name, type
    end

    def search(query)
      results = @client.search(
        index: @index_name,
        type: @type,
        body: { "query" => { "match" => { "_all" => query } } }
      )

      results["hits"]["hits"].map { |r| NeedSearchResult.new(r["_source"]) }
    end
  end
end
