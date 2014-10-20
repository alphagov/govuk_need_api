class OrganisationPresenter
  def initialize(organisation)
    @organisation = organisation
  end

  def present
    {
      id: @organisation.slug,
      name: @organisation.name,
      govuk_status: @organisation.govuk_status,
      abbreviation: @organisation.abbreviation,
      parent_ids: @organisation.parent_ids,
      child_ids: @organisation.child_ids
    }
  end
end
