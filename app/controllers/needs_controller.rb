class NeedsController < ApplicationController
  def index
    query = filtered_params
    @needs = if query.empty?
               Need.all
             else
               orgs = *query["organisation_id"]
               Need.where(:organisation_ids.all => orgs)
             end

    set_expiry 0
    render json: NeedResultSetPresenter.new(@needs).as_json
  end

  def create
    @need = Need.new(filtered_params)

    if @need.save
      render json: NeedPresenter.new(@need).as_json(status: :created),
             status: :created
    else
      error 422, message: :invalid_attributes, errors: @need.errors.full_messages
    end
  end

  private

  def filtered_params
    params.except(:action, :controller)
  end
end
