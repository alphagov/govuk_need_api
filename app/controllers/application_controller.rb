class ApplicationController < ActionController::Base
  protect_from_forgery

  include GDS::SSO::ControllerMethods

  before_filter :authenticate_user!
  before_filter :require_signin_permission!

  private

  def error(code, options = {})
    render json: { _response_info: { status: options.delete(:message) } }.merge(options),
           status: code
  end

end
