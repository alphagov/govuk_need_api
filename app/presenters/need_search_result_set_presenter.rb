class NeedSearchResultSetPresenter
  def initialize(needs, query, view_context)
    @needs = needs
    @query = query
    @view_context = view_context
  end

  def as_json
    {
      _response_info: {
        status: "ok",
        links: links
      },
      total: @needs.count,
      current_page: 1,
      pages: 1,
      start_index: 1,
      page_size: @needs.count,
      results: results
    }
  end

  private
  def results
    @needs.map {|need|
      BasicNeedPresenter.new(need).as_json
    }
  end

  def links
    [{
      rel: "self",
      href: @view_context.needs_url(q: @query)
    }]
  end
end
