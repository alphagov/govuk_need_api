class NeedPresenter
  def initialize(need, view_context)
    @need = need
    @view_context = view_context
  end

  def as_json(options = {})
    {
      _response_info: {
        status: options[:status] || "ok"
      }
    }.merge(present)
  end

  def present
    {
      id: @need.id,
      role: @need.role,
      goal: @need.goal,
      benefit: @need.benefit,
      organisation_ids: @need.organisation_ids,
      organisations: organisations,
      justifications: @need.justifications,
      impact: @need.impact,
      met_when: @need.met_when,
      monthly_user_contacts: @need.monthly_user_contacts,
      monthly_site_views: @need.monthly_site_views,
      monthly_need_views: @need.monthly_need_views,
      monthly_searches: @need.monthly_searches,
      currently_met: @need.currently_met,
      other_evidence: @need.other_evidence,
      legislation: @need.legislation
    }
  end

  private
  def organisations
    @need.organisations.map {|o|
      OrganisationPresenter.new(o).present
    }
  end
end
