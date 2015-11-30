module Search
  class Searcher
    def initialize(search_client, index_name, type)
      @client = search_client
      @index_name = index_name
      @type = type
    end

    def search(querystring, options = {})
      organisation_id = options[:organisation_id]
      raw_page = options[:page].to_i
      if raw_page < 1
        page = 1
      else
        page = raw_page
      end
      response = @client.search(
        index: @index_name,
        type: @type,
        body: {
          "query" => build_query(querystring, organisation_id),
          "size" => Need::PAGE_SIZE,
          "from" => (page - 1) * Need::PAGE_SIZE
        }
      )

      results = response["hits"]["hits"].map { |r| ::Search::NeedSearchResult.new(r["_source"]) }
      ::Search::NeedSearchResultSet.new(results, response["hits"]["total"])
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
          "fields" => %w(_all need_id),
          "query" => querystring,

          # The 'lenient' flag prevents an exception being raised when a string
          # is searched for on the numeric need_id field.
          "lenient" => true
        }
      }
    end
  end
end
