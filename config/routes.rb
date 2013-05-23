Ripple::Application.routes.draw do
  root to: 'high_voltage/pages#show', id: 'index'
  get '/:id', to: 'high_voltage/pages#show'
end
