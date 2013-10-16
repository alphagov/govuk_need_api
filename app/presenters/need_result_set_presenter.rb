class NeedResultSetPresenter
  def initialize(needs, view_context)
    @needs = needs
    @view_context = view_context
  end

  def as_json
    {
      _response_info: {
        status: "ok"
      },
      results: results
    }
  end

  private
  def results
    @needs.map {|need|
      NeedPresenter.new(need, @view_context).present
    }
  end
end
