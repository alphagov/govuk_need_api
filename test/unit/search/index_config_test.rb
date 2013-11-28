require "test_helper"

class IndexConfigTest < ActiveSupport::TestCase
  should "create an index" do
    mock_client = mock("index client")
    mock_client.expects(:create).with(has_entry(index: "maslow-test"))

    Search::IndexConfig.new(mock_client, "maslow-test", nil, nil).create_index
  end

  should "pass in analysis settings" do
    mock_client = mock("index client")
    mock_client.expects(:create).with do |params|
      params[:body] &&
      params[:body]["settings"] &&
      params[:body]["settings"]["analysis"]
    end

    Search::IndexConfig.new(mock_client, "maslow-test", nil, nil).create_index
  end

  should "delete an index" do
    mock_client = mock("index client") do
      expects(:delete).with(index: "maslow-test")
    end

    Search::IndexConfig.new(mock_client, "maslow-test", nil, nil).delete_index
  end

  should "check for an index" do
    mock_client = mock("index client") do
      expects(:exists).with(index: "maslow-test").returns(true)
    end

    index_config = Search::IndexConfig.new(mock_client, "maslow-test", nil, nil)
    assert index_config.index_exists?
  end

  should "put mappings" do
    mock_client = mock("index client") do
      expects(:put_mapping).with(
        index: "maslow-test",
        type: "need",
        body: {
          "need" => {
            "properties" => {
              "foo" => { "type" => "string", "index" => "analyzed", "include_in_all" => true },
              "bar" => { "type" => "long", "index" => "not_analyzed", "include_in_all" => false },
            }
          }
        }
      )
    end

    mock_indexable_class = mock("indexable class")
    mock_indexable_class.expects(:fields).returns([
      stub(name: "foo", type: "string", analyzed?: true, include_in_all?: true),
      stub(name: "bar", type: "long", analyzed?: false, include_in_all?: false)
    ])

    index_config = Search::IndexConfig.new(
      mock_client,
      "maslow-test",
      "need",
      mock_indexable_class
    )
    index_config.put_mappings
  end
end
