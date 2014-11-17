class BasicNeedPresenter
  def initialize(need)
    @need = need
  end

  def as_json
    {
      id: @need.need_id,
      role: @need.role,
      goal: @need.goal,
      benefit: @need.benefit,
      met_when: @need.met_when,
      organisation_ids: @need.organisation_ids,
      organisations: organisations,
      applies_to_all_organisations: @need.applies_to_all_organisations,
      out_of_scope_reason: @need.out_of_scope_reason,
      duplicate_of: @need.duplicate_of,
      status: status,
    }
  end

  private
  def organisations
    @need.organisations.map(&:as_json)
  end

  def status
    if @need.status.present?
      @need.status.is_a?(Hash) ? @need.status : NeedStatusPresenter.new(@need.status).as_json
    else
      nil
    end
  end
end
