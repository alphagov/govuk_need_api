class OrganisationsController < ApplicationController
  def index
    @organisations = Organisation.in_name_order.all

    render json: OrganisationResultSetPresenter.new(@organisations).as_json
  end
end
