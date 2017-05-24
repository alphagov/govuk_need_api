require "link_header"

class NeedsController < ApplicationController
  before_action :load_need
  before_action :check_for_author_params, only: [:create, :update, :closed, :reopen]

  def index
    if params["q"].present?
      result_set = GovukNeedApi.searcher.search(params["q"], params.permit(:organisation_id, :page).to_h)
      @needs = Kaminari.paginate_array(result_set.results, total_count: result_set.total_count)
        .page(params[:page])
        .per(Need::PAGE_SIZE)
    else
      scope = Need

      if params["organisation_id"].present?
        scope = scope.where(organisation_ids: params["organisation_id"])
      end

      scope = scope.where(:need_id.in => need_ids) if need_ids

      @needs = scope.page(params[:page])
    end

    presenter = NeedResultSetPresenter.new(@needs, view_context, scope_params: params.permit(:q, :organisation_id, :ids).to_h)
    response.headers["Link"] = LinkHeader.new(presenter.links).to_s

    set_expiry 0
    render json: presenter.as_json
  end

  def show
    decorated_need = NeedWithChangesets.new(@need)
    render json: response_info("ok").merge(NeedPresenter.new(decorated_need).as_json),
           status: :ok
  end

  def content_id
    render json: @need.content_id
  end

  def create
    # Explicitly deny need IDs in create requests
    # This is a controller-level concern, rather than a model-level one, as we
    # may want to be able to specify need IDs when, for example, importing old
    # needs.
    if params["need_id"].present?
      error(
        422,
        message: :invalid_attributes,
        errors: ["New needs can't specify need IDs"]
      )
      return
    end

    if params["duplicate_of"].present?
      error :unprocessable_entity, message: :invalid_attributes, errors: ["'Duplicate Of' ID cannot be set during create"]
      return
    end

    @need = Need.new(filtered_params)

    if @need.save_as(author_params)
      try_index_need(@need)
      decorated_need = NeedWithChangesets.new(@need)
      render json: response_info("created").merge(NeedPresenter.new(decorated_need).as_json),
             status: :created
    else
      error :unprocessable_entity, message: :invalid_attributes, errors: @need.errors.full_messages
    end
  end

  def destroy
    error :method_not_allowed, message: :method_not_allowed, errors: "Needs cannot be deleted"
  end

  def update
    if @need.closed?
      error :conflict, message: "Cannot update a closed need"
      return
    end

    # Fail explicitly on need ID change
    # `attr_protected`, by default, will silently fail to update the field
    if params["need_id"].present? && params["need_id"].to_i != @need.need_id
      error :unprocessable_entity, message: :invalid_attributes, errors: ["Need IDs cannot change"]
      return
    end

    if params["duplicate_of"].present? && params["duplicate_of"] != @need.duplicate_of
      error :unprocessable_entity, message: :invalid_attributes, errors: ["'Duplicate Of' ID cannot be changed with an update"]
      return
    end

    @need.assign_attributes(filtered_params)
    if @need.valid? && @need.save_as(author_params)
      try_index_need(@need)
      head :no_content
    else
      error :unprocessable_entity, message: :invalid_attributes, errors: @need.errors.full_messages
    end
  end

  def closed
    if @need.closed?
      error :conflict, message: "This need has already been closed"
      return
    end

    duplicate_of = params["duplicate_of"]
    unless duplicate_of.present?
      error :unprocessable_entity, message: :duplicate_of_not_provided, errors: ["'Duplicate Of' id must be provided"]
      return
    end

    if @need.close(duplicate_of, author_params)
      head :no_content
    else
      error :unprocessable_entity, message: :invalid_attributes, errors: @need.errors.full_messages
    end
  end

  def reopen
    unless @need.closed?
      error :not_found, message: :not_found, error: "This need is not closed"
      return
    end

    if @need.reopen(author_params)
      head :no_content
    else
      error :unprocessable_entity, message: :invalid_attributes, errors: @need.errors.full_messages
    end
  end

private

  def load_need
    @need = Need.find(params["id"]) if params["id"]
  rescue Mongoid::Errors::DocumentNotFound
    error :not_found, message: :not_found, error: "No need exists with this ID"
  end

  def check_for_author_params
    unless author_params.any?
      error :unprocessable_entity, message: :author_not_provided, errors: ["Author details must be provided"]
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
    ).to_h
  end

  def author_params
    params.fetch(:author, {}).permit(:name, :email, :uid).to_h
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
