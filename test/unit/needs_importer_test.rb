require_relative '../test_helper'

require 'fileutils'
require 'csv'
require 'needs_importer'

class NeedsImporterTest < ActiveSupport::TestCase

  setup do
    FileUtils.mkdir_p 'tmp'
    CSV.open('tmp/test-needs.csv', "wb") do |csv|
      csv << [ 'As a...', 'I need to...', 'so that...' ]
      csv << [ 'user', 'pay my car tax', 'avoid paying a fine' ]
      csv << [ 'jobseeker', 'log into Jobsearch', "prove that I'm looking for work" ]
    end
  end

  teardown do
    FileUtils.rm 'tmp/test-needs.csv'
  end

  should "import bare-minimum needs" do
    NeedsImporter.new('tmp/test-needs.csv').run

    assert_equal 2, Need.count

    assert Need.where(
      role: "user",
      goal: "pay my car tax",
      benefit: "avoid paying a fine",
    ).first
    assert Need.where(
      role: "jobseeker",
      goal: "log into Jobsearch",
      benefit: "prove that I'm looking for work",
    ).first
  end
end
