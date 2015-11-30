require_relative '../../test_helper'
require 'rake'

class SearchRakeTest < ActiveSupport::TestCase
  setup do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake.application.rake_require("lib/tasks/search", [Rails.root.to_s], [])
    Rake::Task.define_task(:environment)
  end

  context "ensure_index" do
    should "create index and put mappings if index doesn't exist" do
      index = sequence("ensure_index")
      index_config = GovukNeedApi.index_config
      index_config.expects(:index_exists?).returns(false).in_sequence(index)
      index_config.expects(:create_index).in_sequence(index)
      index_config.expects(:put_mappings).in_sequence(index)

      @rake["search:ensure_index"].invoke
    end

    should "attempt to put mappings if index exists" do
      index = sequence("ensure_index")
      index_config = GovukNeedApi.index_config
      index_config.expects(:index_exists?).returns(true).in_sequence(index)
      index_config.expects(:put_mappings).in_sequence(index)
      index_config.expects(:create_index).never

      @rake["search:ensure_index"].invoke
    end
  end

  context "delete_index" do
    should "delete the index if it exists" do
      index = sequence("ensure_index")
      index_config = GovukNeedApi.index_config
      index_config.expects(:index_exists?).returns(true).in_sequence(index)
      index_config.expects(:delete_index).in_sequence(index)

      @rake["search:delete_index"].invoke
    end

    should "do nothing if the index doesn't exist" do
      index = sequence("ensure_index")
      index_config = GovukNeedApi.index_config
      index_config.expects(:index_exists?).returns(false).in_sequence(index)
      index_config.expects(:delete_index).never

      @rake["search:delete_index"].invoke
    end
  end

  context "index_needs" do
    should "index all needs" do
      stub_needs = [stub("need 1"), stub("need 2")]
      Need.expects(:all).at_least_once.returns(stub_needs)

      stub_indexable_needs = [stub("indexable need 1"), stub("indexable need 2")]
      stub_needs.zip(stub_indexable_needs).each do |need, indexable_need|
        Search::IndexableNeed.expects(:new).with(need).returns(indexable_need)
        GovukNeedApi.indexer.expects(:index).with(indexable_need)
      end

      @rake["search:index_needs"].invoke
    end

    should "abort on failure" do
      Need.expects(:all).at_least_once.returns([stub, stub])
      Search::IndexableNeed.expects(:new).once.returns(stub)
      GovukNeedApi.indexer.expects(:index).raises(
        Search::Indexer::IndexingFailed.new(123456)
      )

      assert_raises(RuntimeError) { @rake["search:index_needs"].invoke }
    end
  end
end
