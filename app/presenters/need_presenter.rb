class NeedPresenter
  def initialize(need, view_context)
    @need = need
    @view_context = view_context
  end

  def as_json(options = {})
    {
      _response_info: {
        status: options[:status] || "ok"
      },
      id: @view_context.need_url(@need.id),
      role: @need.role,
      goal: @need.goal,
      benefit: @need.benefit,
      organisation_ids: @need.organisation_ids,
      organisations: organisations,
      justifications: @need.justifications,
      impact: @need.impact,
      met_when: @need.met_when,
      monthly_user_contacts: @need.monthly_user_contacts,
      site_views: @need.site_views,
      need_views: @need.need_views,
      searched_for: @need.searched_for,
      currently_online: @need.currently_online,
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
