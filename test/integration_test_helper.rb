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
    GovukNeedApi.stubs(:searcher).returns(
      Search::Searcher.new(GovukNeedApi.search_client, "maslow_test", "need")
    )
    GovukNeedApi.stubs(:indexer).returns(
      Search::Indexer.new(GovukNeedApi.search_client, "maslow_test", "need")
    )
  end

  def delete_test_index
    indices = GovukNeedApi.search_client.indices
    indices.delete(index: "maslow_test") if indices.exists(index: "maslow_test")
  end
end
