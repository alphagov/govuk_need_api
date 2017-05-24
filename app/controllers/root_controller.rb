class RootController < ApplicationController
  layout false

  skip_before_action :authenticate_user!
  skip_before_action :require_signin_permission!

  def index
    # index.html.erb
  end
end
