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
end
