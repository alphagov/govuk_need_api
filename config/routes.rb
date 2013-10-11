GovukNeedApi::Application.routes.draw do
  resources :organisations, :only => :index
  resources :needs

  get "/healthcheck" => Proc.new { [200, {"Content-type" => "text/plain"}, ["OK"]] }

  root :to => "default#index"
end
