class OrganisationsController < ApplicationController
  def index
    @organisations = Organisation.all

    render json: OrganisationResultSetPresenter.new(@organisations).as_json
  end
end
