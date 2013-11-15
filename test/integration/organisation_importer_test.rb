require './test/integration_test_helper'
require './lib/organisation_importer'
require 'gds_api/test_helpers/organisations'

class OrganisationImporterTest < ActionDispatch::IntegrationTest
  include GdsApi::TestHelpers::Organisations

  setup do
    FactoryGirl.create(:organisation, name: "HM Treasury", slug: "hm-treasury",
                       child_ids: [], parent_ids: [])
    FactoryGirl.create(:organisation, name: "Department for Work & Pensions",
                       slug: "department-for-work-and-pensions",
                       child_ids: [], parent_ids: [])
    FactoryGirl.create(:organisation,
                       name: "Office of the Leader of the House of Commons",
                       slug: "office-of-the-leader-of-the-house-of-commons",
                       child_ids: [], parent_ids: [])
    @hm_treasury = {
      details: { slug: "hm-treasury" },
      title: "HM Treasury",
      child_organisations: [],
      parent_organisations: []
    }
    @dwp = {
      details: { slug: "department-for-work-and-pensions" },
      title: "Department for Work & Pensions",
      child_organisations: [{id:"equality-2025"}],
      parent_organisations: []
    }
    @hoc = {
      details: { slug: "the-office-of-the-leader-of-the-house-of-commons" },
      title: "Office of the Leader of the House of Commons",
      child_organisations: [], parent_organisations: [{id:"cabinet-office"}]
    }
  end

  should "not update an organisation if no attributes have changed" do
    req = request(@hm_treasury)

    OrganisationImporter.new.run

    org = Organisation.where(slug: "hm-treasury").first

    assert_requested req
    assert_equal("HM Treasury", org.name)
    assert_equal("hm-treasury", org.slug)
    assert_equal([], org.child_ids)
    assert_equal([], org.parent_ids)
  end

  should "update an organisation if an attribute has changed" do
    req = request(@hm_treasury.merge(title: "HM Treasure Chest"))

    OrganisationImporter.new.run

    assert_requested req
    assert_equal("HM Treasure Chest",
                 Organisation.where(slug: "hm-treasury").first.name)
  end

  should "update several organisations that have changed attributes" do
    req = request(@dwp, @hoc)
    OrganisationImporter.new.run

    assert_requested req

    dwp = Organisation.where(slug: "department-for-work-and-pensions").first
    hoc = Organisation.where(slug: "the-office-of-the-leader-of-the-house-of-commons").first

    assert_equal(["equality-2025"], dwp.child_ids)
    assert_equal(["cabinet-office"], hoc.parent_ids)
  end

  should "add a new organisation if not already present" do
    req = request({
      details: {
        slug: "ministry-of-defence",
        govuk_status: "live"
      },
      title: "Ministry of Defence",
      abbreviation: "mod",
      child_organisations: [{id:"advisory-committee-on-conscientious-objectors"}],
      parent_organisations: []
    })

    assert_nil Organisation.where(slug: "ministry-of-defence").first

    OrganisationImporter.new.run
    mod = Organisation.where(slug: "ministry-of-defence").first

    assert_requested req
    assert_equal("ministry-of-defence", mod.slug)
    assert_equal("Ministry of Defence", mod.name)
    assert_equal("live", mod.govuk_status)
    assert_equal(["advisory-committee-on-conscientious-objectors"], mod.child_ids)
    assert_equal([], mod.parent_ids)
  end

  def request(*org_details)
    stub_request(:get, Plek.current.find('whitehall-admin')+'/api/organisations')
      .to_return(status: 200,
                 body: {
                   _response_info: { status: "OK" },
                   results: org_details
                 }.to_json
                )
  end
end
