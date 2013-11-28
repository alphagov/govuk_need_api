# This requires the `elasticsearch.rb` initialiser. Due to the fact
# initialisers load in alphabetical order, this will work
search_client = GovukNeedApi.search_client

GovukNeedApi.indexer = Search::Indexer.new(search_client, "maslow", "need")
GovukNeedApi.searcher = Search::Searcher.new(search_client, "maslow", "need")
GovukNeedApi.index_config = Search::IndexConfig.new(
  search_client.indices,
  "maslow",
  "need",
  Search::IndexableNeed
)
