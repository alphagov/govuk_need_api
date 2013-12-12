GovukNeedApi::Application.routes.draw do
  resources :organisations, :only => :index
  resources :needs, :except => [:new, :edit]
  put '/needs/:id/closed', to: 'needs#closed'

  get "/healthcheck" => Proc.new { [200, {"Content-type" => "text/plain"}, ["OK"]] }

  root :to => "root#index"
end
