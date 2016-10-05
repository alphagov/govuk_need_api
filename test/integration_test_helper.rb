require_relative 'test_helper'

class ActionDispatch::IntegrationTest
  include Rack::Test::Methods

  def login_as(user)
    GDS::SSO.test_user = user
  end

  def post_json(url, body, headers = {})
    post url, body, { "CONTENT_TYPE" => "application/json" }.merge(headers)
  end
end
