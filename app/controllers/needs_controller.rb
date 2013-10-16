class NeedsController < ApplicationController
  def index
    @needs = Need.all

    set_expiry 0
    render json: NeedResultSetPresenter.new(@needs, view_context).as_json
  end

  def create
    @need = Need.new(filtered_params)

    if @need.save
      render json: NeedPresenter.new(@need, view_context).as_json(status: :created),
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
