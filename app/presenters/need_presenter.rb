class NeedPresenter
  def initialize(need)
    @need = need
  end

  def present
    {
      id: @need.need_id,
      role: @need.role,
      goal: @need.goal,
      benefit: @need.benefit,
      organisation_ids: @need.organisation_ids,
      organisations: organisations,
      applies_to_all_organisations: @need.applies_to_all_organisations,
      justifications: @need.justifications,
      impact: @need.impact,
      met_when: @need.met_when,
      yearly_user_contacts: @need.yearly_user_contacts,
      yearly_site_views: @need.yearly_site_views,
      yearly_need_views: @need.yearly_need_views,
      yearly_searches: @need.yearly_searches,
      other_evidence: @need.other_evidence,
      legislation: @need.legislation,
      revisions: revisions,
      in_scope: @need.in_scope,
      out_of_scope_reason: @need.out_of_scope_reason,
      duplicate_of: @need.duplicate_of
    }
  end

  private
  def organisations
    @need.organisations.map {|o|
      OrganisationPresenter.new(o).present
    }
  end

  def revisions
    @need.changesets.take(5).map { |changeset|
      ChangesetPresenter.new(changeset).present
    }
  end
end
