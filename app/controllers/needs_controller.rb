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

  def create
    @need = Need.new(filtered_params)

    if @need.save_as(params[:author])
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
end
