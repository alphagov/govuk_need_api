require "search/searcher"
require "search/indexer"

# This requires the `elasticsearch.rb` initialiser. Due to the fact
# initialisers load in alphabetical order, this will work
search_client = GovukNeedApi.search_client

GovukNeedApi.indexer = Search::Indexer.new(search_client, "maslow", "need")
GovukNeedApi.searcher = Search::Searcher.new(search_client, "maslow", "need")
