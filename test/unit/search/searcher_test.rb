require "test_helper"

class SearcherTest < ActiveSupport::TestCase

  def body_for_query(query)
    { "query" => { "match" => { "_all" => query } } }
  end

  should "do a search" do
    expected_body = body_for_query("cheese")
    client = mock("client") do
      expects(:search).with(
        index: "foo",
        type: "bang",
        body: expected_body
      ).returns(
        "hits" => {
          "hits" => [
            { "_source" => { "role" => "fishmonger" } }
          ]
        }
      )
    end

    results = Search::Searcher.new(client, "foo", "bang").search("cheese")
    assert_equal ["fishmonger"], results.map(&:role)
  end
end
