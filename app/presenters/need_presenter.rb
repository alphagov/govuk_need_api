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
      benefit: @need.benefit
    }
  end
end
