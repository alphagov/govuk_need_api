class ApplicationController < ActionController::Base
  protect_from_forgery

  include GDS::SSO::ControllerMethods

  before_action :authenticate_user!
  before_action :require_signin_permission!

  private

  def error(code, options = {})
    render json: { _response_info: { status: options.delete(:message) } }.merge(options),
           status: code
  end

  def set_expiry(duration)
    expires_in duration, public: true unless Rails.env.development?
  end
end
