Ripple::Application.routes.draw do
  root to: 'docs#show', id: 'index'
  get '/:id', to: 'docs#show', constraints: {id: /\w+/}
end
