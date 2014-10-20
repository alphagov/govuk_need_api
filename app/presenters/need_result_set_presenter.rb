require 'link_header'

class NeedResultSetPresenter
  def initialize(needs, view_context, options = {})
    @needs = needs
    @view_context = view_context
    @scope_params = options[:scope_params] || {}
  end

  def as_json
    {
      _response_info: {
        status: "ok",
        links: links.map {|l| { "href" => l.href }.merge(l.attrs) }
      },
      total: @needs.count,
      current_page: @needs.current_page,
      pages: @needs.total_pages,
      start_index: start_index,
      page_size: @needs.to_a.size,
      results: results
    }
  end

  def links
    @links ||= build_links
  end

  private
  def results
    @needs.map {|need|
      BasicNeedPresenter.new(need).as_json
    }
  end

  def build_links
    [].tap {|links|

      unless @needs.first_page?
        links << LinkHeader::Link.new(
          @view_context.needs_url(@scope_params.merge(page: @needs.current_page-1)),
          [["rel", "previous"]]
        )
      end

      unless @needs.last_page?
        links << LinkHeader::Link.new(
          @view_context.needs_url(@scope_params.merge(page: @needs.current_page+1)),
          [["rel", "next"]]
        )
      end

      links << LinkHeader::Link.new(
        @view_context.needs_url(@scope_params.merge(page: @needs.current_page)),
        [["rel", "self"]]
      )
    }
  end

  def start_index
    @needs.offset_value+1
  end
end
