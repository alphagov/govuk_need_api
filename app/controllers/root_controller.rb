class RootController < ApplicationController
  layout false

  skip_before_filter :authenticate_user!
  skip_before_filter :require_signin_permission!

  def index
    # index.html.erb
  end
end
