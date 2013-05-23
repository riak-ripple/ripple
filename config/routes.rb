Ripple::Application.routes.draw do
  root to: 'docs#show', id: 'index'
  get '/p/:id', to: 'docs#show'
end
