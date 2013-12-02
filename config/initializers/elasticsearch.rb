# NOTE: the `search.rb` initializer relies on this file being loaded first,
# which it currently manages because it comes first in the alphabet.
GovukNeedApi.search_client = Elasticsearch::Client.new(host: "localhost:9200")
