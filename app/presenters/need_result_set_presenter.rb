class NeedResultSetPresenter
  def initialize(needs)
    @needs = needs
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
      NeedPresenter.new(need).present
    }
  end
end
