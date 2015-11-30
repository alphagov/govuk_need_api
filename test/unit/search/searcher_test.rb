require "test_helper"

class SearcherTest < ActiveSupport::TestCase
  def body_for_query(query)
    {
      "query" => {
        "multi_match" => {
          "fields" => %w(_all need_id),
          "query" => query,
          "lenient" => true
        }
      }
    }
  end

  def single_result_response
    {
      "hits" => {
        "hits" => [
          { "_source" => { "role" => "fishmonger" } }
        ]
      }
    }
  end

  should "send a multi_match query to the need API" do
    client = mock("client")
    client.expects(:search).with { |search_params|
      search_params[:body]["query"].keys == ["multi_match"]
    }.returns(single_result_response)

    Search::Searcher.new(client, "foo", "bang").search("baz")
  end

  should "search on the _all field and the need_id field" do
    client = mock("client")
    client.expects(:search).with { |search_params|
      query_params = search_params[:body]["query"].values.first
      query_params["fields"].include? "_all"
      query_params["fields"].include? "need_id"
    }.returns(single_result_response)

    Search::Searcher.new(client, "foo", "bang").search("baz")
  end

  should "do a lenient search" do
    client = mock("client")
    client.expects(:search).with { |search_params|
      query_params = search_params[:body]["query"].values.first
      query_params["lenient"] == true
    }.returns(single_result_response)

    Search::Searcher.new(client, "foo", "bang").search("baz")
  end

  should "pass the original query" do
    client = mock("client")
    client.expects(:search).with { |search_params|
      query_params = search_params[:body]["query"].values.first
      query_params["query"] == "baz"
    }.returns(single_result_response)

    Search::Searcher.new(client, "foo", "bang").search("baz")
  end

  should "ask for the first 50 results" do
    client = mock("client")
    client.expects(:search).with { |search_params|
      50 == search_params[:body]["size"] &&
        0 == search_params[:body]["from"]
    }.returns(single_result_response)

    Search::Searcher.new(client, "foo", "bang").search("baz")
  end

  should "ask for the next 50 results" do
    client = mock("client")
    client.expects(:search).with { |search_params|
      50 == search_params[:body]["size"] &&
        50 == search_params[:body]["from"]
    }.returns(single_result_response)

    Search::Searcher.new(client, "foo", "bang").search("baz", page: 2)
  end

  should "parse out the search results" do
    client = mock("client")
    client.expects(:search).returns(single_result_response)

    result_set = Search::Searcher.new(client, "foo", "bang").search("cheese")
    assert_equal ["fishmonger"], result_set.results.map(&:role)
  end
end
