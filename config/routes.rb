Rails.application.routes.draw do
  resources :needs, except: [:new, :edit]
  resources :notes, only: [:create]

  get '/needs/:id/content_id', to: 'needs#content_id'

  put '/needs/:id/closed', to: 'needs#closed'
  delete '/needs/:id/closed', to: 'needs#reopen'

  get "/healthcheck" => Proc.new { [200, {"Content-type" => "text/plain"}, ["OK"]] }

  root to: "root#index"
end
