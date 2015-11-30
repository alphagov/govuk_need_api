require './test/test_helper'
require './lib/organisation_importer'

class OrganisationImporterTest < ActionDispatch::IntegrationTest
  def stub_api_with_organisations(*organisations_atts)
    organisations = organisations_atts.map {|o|
      OpenStruct.new(
        title: o[:name],
        details: OpenStruct.new(slug: o[:slug],
                                content_id: o[:content_id],
                                govuk_status: o[:govuk_status],
                                abbreviation: o[:abbreviation]),
        child_organisations: o[:child_ids],
        parent_organisations: o[:parent_ids]
      )
    }
    stub_subsequent_pages = stub(with_subsequent_pages: organisations)
    GdsApi::Organisations.any_instance.expects(:organisations)
      .returns(stub_subsequent_pages)
  end

  should "not update an organisation if no attributes have changed" do
    organisation_atts = {
      content_id: SecureRandom.uuid,
      name: "HM Treasury",
      slug: "hm-treasury",
      child_ids: [],
      parent_ids: []
    }
    Organisation.create!(organisation_atts)
    stub_api_with_organisations(organisation_atts)

    OrganisationImporter.new.run

    org = Organisation.where(slug: "hm-treasury").first

    assert_equal("HM Treasury", org.name)
    assert_equal("hm-treasury", org.slug)
    assert_equal(organisation_atts[:content_id], org.content_id)
    assert_equal([], org.child_ids)
    assert_equal([], org.parent_ids)
  end

  should "update an organisation if an attribute has changed" do
    organisation_atts = {
      content_id: SecureRandom.uuid,
      name: "HM Treasury",
      slug: "hm-treasury",
      abbreviation: "HMT",
      child_ids: [],
      parent_ids: []
    }
    Organisation.create!(organisation_atts.except(:content_id))
    stub_api_with_organisations(organisation_atts.merge(abbreviation: "HT"))

    OrganisationImporter.new.run

    org = Organisation.where(slug: 'hm-treasury').first
    assert_equal "HT", org.abbreviation
    assert_equal organisation_atts[:content_id], org.content_id
  end

  should "update/add several organisations that have changed" do
    dwp_atts = {
      content_id: SecureRandom.uuid,
      slug: "department-for-work-and-pensions",
      name: "Department for Work & Pensions",
      child_ids: [OpenStruct.new(id: "equality-2025")],
      parent_ids: []
    }
    Organisation.create!(dwp_atts.merge(child_ids: ["equality-2025"]))

    hoc_atts = {
      content_id: SecureRandom.uuid,
      slug: "the-office-of-the-leader-of-the-house-of-commons",
      name: "Office of the Leader of the House of Commons",
      child_ids: [],
      parent_ids: [OpenStruct.new(id: "cabinet-office")]
    }
    Organisation.create!(hoc_atts.merge(parent_ids: ["cabinet-office"]))

    mod_atts = {
      content_id: SecureRandom.uuid,
      slug: "ministry-of-defence",
      name: "Ministry of Defence",
      abbreviation: "mod",
      govuk_status: "live",
      child_ids: [OpenStruct.new(id: "advisory-committee")],
      parent_ids: []
    }

    stub_api_with_organisations(dwp_atts, hoc_atts, mod_atts)

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
    assert_equal(["advisory-committee"], mod.child_ids)
    assert_equal([], mod.parent_ids)
  end
end
