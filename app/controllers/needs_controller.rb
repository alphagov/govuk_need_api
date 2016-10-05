require "link_header"

class NeedsController < ApplicationController
  before_filter :load_need
  before_filter :check_for_author_params, only: [:create, :update, :closed, :reopen]

  def index
    scope = Need

    scope = scope.where(:need_id.in => need_ids) if need_ids

    if params["organisation_id"].present?
      scope = scope.where(organisation_ids: params["organisation_id"])
    end

    if params["q"].present?
      # NOTE: if the query looks like it might be a need_id (e.g. it's all
      # numbers) then don't use text_search as the index in mongo 2.4 doesn't
      # seem to like searching on the integer need_id field
      if params["q"] !~ /\A\d+\Z/
        scope = scope.text_search(params['q'])
        # NOTE: the results of text_search aren't a standard mongoid result set
        # so they don't have kaminari pagination mixed in.  Also text search
        # in mongo 2.4 doesn't support skip, so you can't do real pagination
        # in the driver.
        @needs = Kaminari.paginate_array(scope.to_a, total_count: scope.count)
          .page(params[:page])
          .per(Need::PAGE_SIZE)
      else
        scope = scope.where(need_id: params["q"].to_i)
      end
    end

    @needs = scope.page(params[:page]) if @needs.nil?

    presenter = NeedResultSetPresenter.new(@needs, view_context, scope_params: params.slice(:q, :organisation_id, :ids))
    response.headers["Link"] = LinkHeader.new(presenter.links).to_s

    set_expiry 0
    render json: presenter.as_json
  end

  def show
    decorated_need = NeedWithChangesets.new(@need)
    render json: response_info("ok").merge(NeedPresenter.new(decorated_need).as_json),
           status: :ok
  end

  def create
    # Explicitly deny need IDs in create requests
    # This is a controller-level concern, rather than a model-level one, as we
    # may want to be able to specify need IDs when, for example, importing old
    # needs.
    if params["need_id"]
      error(
        422,
        message: :invalid_attributes,
        errors: ["New needs can't specify need IDs"]
      )
      return
    end

    if params["duplicate_of"]
      error 422, message: :invalid_attributes, errors: ["'Duplicate Of' ID cannot be set during create"]
      return
    end

    @need = Need.new(filtered_params)

    if @need.save_as(author_params)
      try_index_need(@need)
      decorated_need = NeedWithChangesets.new(@need)
      render json: response_info("created").merge(NeedPresenter.new(decorated_need).as_json),
             status: :created
    else
      error 422, message: :invalid_attributes, errors: @need.errors.full_messages
    end
  end

  def destroy
    error 405, message: :method_not_allowed, errors: "Needs cannot be deleted"
  end

  def update
    if @need.closed?
      error 409, message: "Cannot update a closed need"
      return
    end

    # Fail explicitly on need ID change
    # `attr_protected`, by default, will silently fail to update the field
    if params["need_id"] && params["need_id"].to_i != @need.need_id
      error 422, message: :invalid_attributes, errors: ["Need IDs cannot change"]
      return
    end

    if params["duplicate_of"] != @need.duplicate_of
      error 422, message: :invalid_attributes, errors: ["'Duplicate Of' ID cannot be changed with an update"]
      return
    end

    @need.assign_attributes(filtered_params)
    if @need.valid? && @need.save_as(author_params)
      try_index_need(@need)
      render nothing: true, status: 204
    else
      error 422, message: :invalid_attributes, errors: @need.errors.full_messages
    end
  end

  def closed
    if @need.closed?
      error 409, message: "This need has already been closed"
      return
    end

    duplicate_of = params["duplicate_of"]
    unless duplicate_of.present?
      error 422, message: :duplicate_of_not_provided, errors: ["'Duplicate Of' id must be provided"]
      return
    end

    if @need.close(duplicate_of, author_params)
      render nothing: true, status: 204
    else
      error 422, message: :invalid_attributes, errors: @need.errors.full_messages
    end
  end

  def reopen
    unless @need.closed?
      error 404, message: :not_found, error: "This need is not closed"
      return
    end

    if @need.reopen(author_params)
      render nothing: true, status: 204
    else
      error 422, message: :invalid_attributes, errors: @need.errors.full_messages
    end
  end

  private

  def load_need
    @need = Need.find(params["id"]) if params["id"]
  rescue Mongoid::Errors::DocumentNotFound
    error 404, message: :not_found, error: "No need exists with this ID"
  end

  def check_for_author_params
    unless author_params.any?
      error 422, message: :author_not_provided, errors: ["Author details must be provided"]
    end
  end

  def filtered_params
    params.permit(
      :role,
      :goal,
      :benefit,
      :impact,
      :yearly_user_contacts,
      :yearly_site_views,
      :yearly_need_views,
      :yearly_searches,
      :other_evidence,
      :legislation,
      :applies_to_all_organisations,
      :author,
      met_when: [],
      organisation_ids: [],
      justifications: [],
      status: [
        :description,
        :additional_comments,
        :validation_conditions,
        reasons: [],
      ],
    )
  end

  def author_params
    author = params[:author] || { }
    author.slice(:name, :email, :uid)
  end

  def try_index_need(need)
    GovukNeedApi.indexer.index(Search::IndexableNeed.new(need))
    true
  rescue Search::Indexer::IndexingFailed => e
    Airbrake.notify_or_ignore(e)
    false
  end

  def need_ids
    params[:ids].split(',').map(&:strip).map(&:to_i) if params[:ids]
  end

  def response_info(status)
    {
      _response_info: {
        status: status
      }
    }
  end
end
