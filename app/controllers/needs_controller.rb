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
    render json: NeedPresenter.new(need).as_json(status: :ok),
           status: :ok
  rescue Mongoid::Errors::DocumentNotFound
    error 404, message: :not_found, error: "No need exists with this ID"
  end

  def create
    @need = Need.new(filtered_params)

    unless author_params.any?
      error 422, message: :author_not_provided, errors: ["Author details must be provided"]
      return
    end

    if @need.save_as(author_params)
      render json: NeedPresenter.new(@need).as_json(status: :created),
             status: :created
    else
      error 422, message: :invalid_attributes, errors: @need.errors.full_messages
    end
  end

  def destroy
    error 405, message: :method_not_allowed, errors: "Needs cannot be deleted"
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
