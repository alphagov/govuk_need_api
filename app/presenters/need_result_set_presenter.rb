class NeedResultSetPresenter
  def initialize(needs, view_context)
    @needs = needs
    @view_context = view_context
  end

  def as_json
    {
      _response_info: {
        status: "ok",
        links: links
      },
      total: @needs.count,
      current_page: @needs.current_page,
      pages: @needs.total_pages,
      start_index: start_index,
      page_size: @needs.to_a.size,
      results: results
    }
  end

  private
  def results
    @needs.map {|need|
      BasicNeedPresenter.new(need).present
    }
  end

  def links
    [].tap {|links|

      unless @needs.first_page?
        links << {
          rel: "previous",
          href: @view_context.needs_url(page: @needs.current_page-1)
        }
      end

      unless @needs.last_page?
        links << {
          rel: "next",
          href: @view_context.needs_url(page: @needs.current_page+1)
        }
      end

      links << {
        rel: "self",
        href: @view_context.needs_url(page: @needs.current_page)
      }
    }
  end

  def start_index
    @needs.offset_value+1
  end
end
