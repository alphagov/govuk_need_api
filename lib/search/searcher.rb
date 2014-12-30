module Search
  class Searcher
    def initialize(search_client, index_name, type)
      @client = search_client
      @index_name, @type = index_name, type
    end

    def search(querystring, organisation_id=nil)
      results = @client.search(
        index: @index_name,
        type: @type,
        body: {
          "query" => build_query(querystring, organisation_id),
          "size" => 50,
        }
      )

      results["hits"]["hits"].map { |r| Search::NeedSearchResult.new(r["_source"]) }
    end

    def build_query(querystring, organisation_id)
      if organisation_id
        {
          "filtered" => {
            "filter" => {
              "term" => {
                "organisation_ids" => organisation_id
              }
            },
            "query" => querystring_query(querystring)
          }
        }
      else
        querystring_query(querystring)
      end
    end

    def querystring_query(querystring)
      {
        "multi_match" => {
          "fields" => [ "_all", "need_id" ],
          "query" => querystring,

          # The 'lenient' flag prevents an exception being raised when a string
          # is searched for on the numeric need_id field.
          "lenient" => true
        }
      }
    end
  end
end
