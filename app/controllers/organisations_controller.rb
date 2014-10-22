class OrganisationsController < ApplicationController
  def index
    organisations = Organisation.in_name_order.all

    render json: {
      _response_info: {
        status: "ok"
      },
      organisations: organisations.map(&:as_json)
    }
  end
end
