require_relative '../../test_helper'
require 'search/index_config'
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
end
