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
        body: {
          "query" => {
            "multi_match" => {
              "fields" => [ "_all", "need_id" ],
              "query" => query,

              # The 'lenient' flag prevents an exception being raised when a string
              # is searched for on the numeric need_id field.
              "lenient" => true
            }
          }
        }
      )

      results["hits"]["hits"].map { |r| Search::NeedSearchResult.new(r["_source"]) }
    end
  end
end
