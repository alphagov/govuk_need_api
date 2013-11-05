class BasicNeedPresenter
  def initialize(need)
    @need = need
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
      id: @need.need_id,
      role: @need.role,
      goal: @need.goal,
      benefit: @need.benefit,
      organisation_ids: @need.organisation_ids,
      organisations: organisations
    }
  end

  private
  def organisations
    @need.organisations.map {|o|
      OrganisationPresenter.new(o).present
    }
  end
end
