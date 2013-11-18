require_relative '../../test_helper'
require 'rake'

class OrganisationsImportRakeTest < ActiveSupport::TestCase
  setup do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake.application.rake_require("lib/tasks/organisations", [Rails.root.to_s], [])
    Rake::Task.define_task(:environment)
  end

  context "organisations:import" do
    should "call OrganisationImporter run" do
      OrganisationImporter.any_instance.expects(:run)
      @rake["organisations:import"].invoke
    end
  end
end
