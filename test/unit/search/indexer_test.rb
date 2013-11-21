require "test_helper"
require "search/indexer"

class IndexerTest < ActiveSupport::TestCase

  should "index a presented document" do
    client = mock("client") do
      expects(:index).with(
        index: "foo",
        type: "bang",
        id: 123456,
        body: { :wibble => true }
      )
    end
    need = mock("indexable need") do
      expects(:need_id).returns(123456)
      expects(:present).returns({ :wibble => true })
    end

    Search::Indexer.new(client, "foo", "bang").index(need)
  end
end
