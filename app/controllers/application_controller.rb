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

  def set_expiry(duration)
    unless Rails.env.development?
      expires_in duration, :public => true
    end
  end

end
