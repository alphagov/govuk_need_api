require "test_helper"

class IndexerTest < ActiveSupport::TestCase
  should "index a presented document" do
    client = mock("client") do
      expects(:index).with(
        index: "foo",
        type: "bang",
        id: 123456,
        body: { wibble: true }
      )
    end
    need = mock("indexable need") do
      expects(:need_id).returns(123456)
      expects(:present).returns(wibble: true)
    end

    Search::Indexer.new(client, "foo", "bang").index(need)
  end

  should "wrap known errors" do
    error_classes = [
      Elasticsearch::Transport::Transport::Error,
      Elasticsearch::Transport::Transport::ServerError,
      Elasticsearch::Transport::Transport::SnifferTimeoutError
    ]
    need = stub("indexable need") do
      stubs(:need_id).returns(123456)
      stubs(:present).returns(wibble: true)
    end

    error_classes.each do |error_class|
      client = mock("client") do
        expects(:index).raises(error_class)
      end

      assert_raises(Search::Indexer::IndexingFailed) do
        Search::Indexer.new(client, "foo", "bang").index(need)
      end
    end
  end

  should "not wrap unanticipated errors" do
    need = stub("indexable need") do
      stubs(:need_id).returns(123456)
      stubs(:present).returns(wibble: true)
    end

    client = mock("client") do
      expects(:index).raises(ArgumentError)
    end

    assert_raises(ArgumentError) do
      Search::Indexer.new(client, "foo", "bang").index(need)
    end
  end
end
