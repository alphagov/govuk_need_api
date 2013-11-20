class IndexableNeed
  def initialize(need)
    @need = need
  end

  def present
    {
      need_id: @need.need_id,
      role: @need.role,
      goal: @need.goal,
      benefit: @need.benefit,
      met_when: @need.met_when,
      legislation: @need.legislation,
      other_evidence: @need.other_evidence
    }
  end
end
