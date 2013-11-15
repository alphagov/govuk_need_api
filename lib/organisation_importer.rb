require 'gds_api/organisations'

class OrganisationImporter
  def run
    api = GdsApi::Organisations.new(Plek.current.find('whitehall-admin'))
    api.organisations.with_subsequent_pages.to_a.each do |org|
      create_organisation(org)
    end
  end

  private

  def create_organisation(org)
    child_ids = related_organisation_slugs(org.child_organisations)
    parent_ids = related_organisation_slugs(org.parent_organisations)

    org_hash = {
      :name => org.title,
      :slug => org.details.slug,
      :abbreviation => org.details.abbreviation,
      :govuk_status => org.details.govuk_status,
      :parent_ids => parent_ids,
      :child_ids => child_ids
    }

    o = Organisation.where(slug: org.details.slug).first

    if o
      o.update_attributes(org_hash)
    else
      Organisation.new(org_hash).save
    end
  end

  def related_organisation_slugs(arr)
    arr.map do |a|
      a.id.split('/').last
    end
  end
end
