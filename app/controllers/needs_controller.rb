class NeedsController < ApplicationController
  before_filter :load_need
  before_filter :check_for_author_params, only: [:create, :update, :closed, :reopen]

  def index
    scope = Need

    if params["q"].present?
      search(params["q"]) and return
    end

    if org = params["organisation_id"] and org.present?
      scope = scope.where(:organisation_ids => org)
    end
    @needs = scope.page(params[:page])

    set_expiry 0
    render json: NeedResultSetPresenter.new(@needs, view_context).as_json
  end

  def show
    decorated_need = NeedWithChangesets.new(@need)
    render json: NeedPresenter.new(decorated_need).as_json(status: :ok),
           status: :ok
  end

  def create
    # Explicitly deny need IDs in create requests
    # This is a controller-level concern, rather than a model-level one, as we
    # may want to be able to specify need IDs when, for example, importing old
    # needs.
    if filtered_params["need_id"]
      error(
        422,
        message: :invalid_attributes,
        errors: ["New needs can't specify need IDs"]
      )
      return
    end
    @need = Need.new(filtered_params)

    if @need.save_as(author_params)
      try_index_need(@need)
      decorated_need = NeedWithChangesets.new(@need)
      render json: NeedPresenter.new(decorated_need).as_json(status: :created),
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

    @need.assign_attributes(filtered_params)
    if @need.valid? and @need.save_as(author_params)
      try_index_need(@need)
      render nothing: true, status: 204
    else
      error 422, message: :invalid_attributes, errors: @need.errors.full_messages
    end
  end

  def closed
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
      @need.reload
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

  def search(query)
    # TODO: reject page parameter

    results = GovukNeedApi.searcher.search(query)
    set_expiry 0

    presenter = NeedSearchResultSetPresenter.new(results, query, view_context)
    render json: presenter.as_json
  end

  def filtered_params
    params.except(:action, :controller, :author)
  end

  def author_params
    author = params[:author] || { }
    author.slice(:name, :email, :uid)
  end

  def try_index_need(need)
    GovukNeedApi.indexer.index(Search::IndexableNeed.new(need))
    true
  rescue Search::Indexer::IndexingFailed => e
    ExceptionNotifier::Notifier.background_exception_notification(e)
    false
  end
end
