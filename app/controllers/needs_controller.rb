class NeedsController < ApplicationController
  def index
    org = params["organisation_id"]
    @needs = if org.present?
               Need.where(:organisation_ids => org)
             else
               Need.all
             end

    set_expiry 0
    render json: NeedResultSetPresenter.new(@needs).as_json
  end

  def show
    need = Need.find(params["id"])
    decorated_need = NeedDecorator.new(need)
    render json: NeedPresenter.new(decorated_need).as_json(status: :ok),
           status: :ok
  rescue Mongoid::Errors::DocumentNotFound
    error 404, message: :not_found, error: "No need exists with this ID"
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

    unless author_params.any?
      error 422, message: :author_not_provided, errors: ["Author details must be provided"]
      return
    end

    if @need.save_as(author_params)
      decorated_need = NeedDecorator.new(@need)
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
    @need = Need.find(params["id"])

    # Fail explicitly on need ID change
    # `attr_protected`, by default, will silently fail to update the field
    if params["need_id"] && params["need_id"].to_i != @need.need_id
      error 422, message: :invalid_attributes, errors: ["Need IDs cannot change"]
      return
    end

    @need.assign_attributes(filtered_params)
    if @need.valid?
      @need.save!
      render nothing: true, status: 204
    else
      error 422, message: :invalid_attributes, errors: @need.errors.full_messages
    end
  rescue Mongoid::Errors::DocumentNotFound
    error 404, message: :not_found, error: "No need exists with this ID"
  end

  private

  def filtered_params
    params.except(:action, :controller, :author)
  end

  def author_params
    author = params[:author] || { }
    author.slice(:name, :email, :uid)
  end
end
