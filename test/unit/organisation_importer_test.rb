require './test/test_helper'
require './lib/organisation_importer'

class OrganisationImporterTest < ActionDispatch::IntegrationTest
  setup do
    FactoryGirl.create(:organisation, name: "HM Treasury", slug: "hm-treasury",
                       child_ids: [], parent_ids: [])
    @hm_treasury = OpenStruct.new(
      details: OpenStruct.new(slug: "hm-treasury"),
      title: "HM Treasury",
      child_organisations: [],
      parent_organisations: []
    )

    FactoryGirl.create(:organisation, name: "Department for Work & Pensions",
                       slug: "department-for-work-and-pensions",
                       child_ids: [], parent_ids: [])
    @dwp = OpenStruct.new(
      details: OpenStruct.new(slug: "department-for-work-and-pensions"),
      title: "Department for Work & Pensions",
      child_organisations: [OpenStruct.new(id:"equality-2025")],
      parent_organisations: []
    )

    FactoryGirl.create(:organisation,
                       name: "Office of the Leader of the House of Commons",
                       slug: "office-of-the-leader-of-the-house-of-commons",
                       child_ids: [], parent_ids: [])
    @hoc = OpenStruct.new(
      details: OpenStruct.new(slug: "the-office-of-the-leader-of-the-house-of-commons"),
      title: "Office of the Leader of the House of Commons",
      child_organisations: [], parent_organisations: [OpenStruct.new(id:"cabinet-office")]
    )
  end

  def stub_and_verify_api_with(*organisations)
    stub_subsequent_pages = stub
    GdsApi::Organisations.any_instance.expects(:organisations)
      .returns(stub_subsequent_pages)
    stub_subsequent_pages.expects(:with_subsequent_pages)
      .returns(organisations)
  end

  should "not update an organisation if no attributes have changed" do
    stub_and_verify_api_with(@hm_treasury)

    OrganisationImporter.new.run

    org = Organisation.where(slug: "hm-treasury").first

    assert_equal("HM Treasury", org.name)
    assert_equal("hm-treasury", org.slug)
    assert_equal([], org.child_ids)
    assert_equal([], org.parent_ids)
  end

  should "update an organisation if an attribute has changed" do
    @hm_treasury.title = "HM Treasure Chest"
    stub_and_verify_api_with(@hm_treasury)

    OrganisationImporter.new.run

    assert_equal("HM Treasure Chest",
                 Organisation.where(slug: "hm-treasury").first.name)
  end

  should "update/add several organisations that have changed" do
    stubbed_mod = OpenStruct.new(
      details: OpenStruct.new(
        slug: "ministry-of-defence",
        govuk_status: "live"
      ),
      title: "Ministry of Defence",
      abbreviation: "mod",
      child_organisations: [OpenStruct.new(id:"advisory-committee-on-conscientious-objectors")],
      parent_organisations: []
    )
    stub_and_verify_api_with(@dwp, @hoc, stubbed_mod)

    assert_nil Organisation.where(slug: "ministry-of-defence").first

    OrganisationImporter.new.run

    dwp = Organisation.where(slug: "department-for-work-and-pensions").first
    assert_equal(["equality-2025"], dwp.child_ids)

    hoc = Organisation.where(slug: "the-office-of-the-leader-of-the-house-of-commons").first
    assert_equal(["cabinet-office"], hoc.parent_ids)

    mod = Organisation.where(slug: "ministry-of-defence").first
    assert_equal("ministry-of-defence", mod.slug)
    assert_equal("Ministry of Defence", mod.name)
    assert_equal("live", mod.govuk_status)
    assert_equal(["advisory-committee-on-conscientious-objectors"], mod.child_ids)
    assert_equal([], mod.parent_ids)
  end
end
