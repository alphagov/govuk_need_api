require_relative 'test_helper'

class ActionDispatch::IntegrationTest
  include Rack::Test::Methods

  def login_as(user)
    GDS::SSO.test_user = user
  end

  def post_json(url, body, headers = {})
    post url, body, { "CONTENT_TYPE" => "application/json" }.merge(headers)
  end

  def use_test_index
    search_client = GovukNeedApi.search_client
    GovukNeedApi.stubs(:searcher).returns(
      Search::Searcher.new(search_client, "maslow_test", "need")
    )
    GovukNeedApi.stubs(:indexer).returns(
      Search::Indexer.new(search_client, "maslow_test", "need")
    )
    search_client.indices.create(index: "maslow_test")

    # Wait until the new index reports it's started up
    timeout(2) do
      until(elasticsearch_index_ready("maslow_test"))
        # Do nothing: the conditional does the work
      end
    end
  end

  def delete_test_index
    indices = GovukNeedApi.search_client.indices
    indices.delete(index: "maslow_test") if indices.exists(index: "maslow_test")
  end

  def refresh_index
    GovukNeedApi.search_client.indices.refresh(index: "maslow_test")
  end

  def elasticsearch_index_ready(index_name)
    index_status = GovukNeedApi.search_client.indices.status(index: index_name)
    shards_by_node = index_status["indices"][index_name]["shards"]
    all_shards = shards_by_node.values.flatten
    all_shards.all? { |shard| shard["state"] == "STARTED" }
  end
end
