class OrganisationPresenter
  def initialize(organisation)
    @organisation = organisation
  end

  def as_json
    {
      _response_info: {
        status: "ok"
      }
    }.merge(present)
  end

  def present
    {
      id: @organisation.slug,
      name: @organisation.name
    }
  end
end
