require 'gds_api/organisations'

class OrganisationImporter
  def run
    api = GdsApi::Organisations.new(Plek.current.find('whitehall-admin'))
    api.organisations.with_subsequent_pages.to_a.each do |org|
      create_or_update_organisation(org)
    end
  end

  private

  def create_or_update_organisation(organisation_from_api)
    child_ids = related_organisation_slugs(organisation_from_api.child_organisations)
    parent_ids = related_organisation_slugs(organisation_from_api.parent_organisations)

    organisation_atts = {
      :name => organisation_from_api.title,
      :slug => organisation_from_api.details.slug,
      :abbreviation => organisation_from_api.details.abbreviation,
      :govuk_status => organisation_from_api.details.govuk_status,
      :parent_ids => parent_ids,
      :child_ids => child_ids
    }

    existing_organisation = Organisation.where(slug: organisation_from_api.details.slug).first

    if existing_organisation.present?
      existing_organisation.update_attributes(organisation_atts)
    else
      Organisation.new(organisation_atts).save
    end
  end

  def related_organisation_slugs(arr)
    arr.map do |a|
      a.id.split('/').last
    end
  end
end
