class OrganisationResultSetPresenter

  def initialize(organisations)
    @organisations = organisations
  end

  def as_json
    response_info.merge(
      organisations: @organisations.map {|organisation|
        OrganisationPresenter.new(organisation).present
      }
    )
  end

  private
  def response_info
    {
      _response_info: {
        status: "ok"
      }
    }
  end
end
