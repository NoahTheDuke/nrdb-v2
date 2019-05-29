Rails.application.routes.draw do
  get 'password_resets/new'

  get 'password_resets/edit'

  get 'sessions/new'

  root 'static_pages#home'

  get '/help', to: 'static_pages#help'
  get '/contact', to: 'static_pages#contact'
  get '/signup', to: 'users#new'
  post '/signup', to: 'users#create'

  get '/login', to: 'sessions#new'
  post '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

  resources :users

  resources :account_activations, only: %i[edit]
  resources :password_resets, only: %i[new create edit update]

  resources :nr_cycles, param: :code
  resources :nr_sets, param: :code
  resources :nr_set_types
  resources :cards, param: :code, only: %i[index show]
  resources :legality_types

  resources :search, only: [:index]

  get '/card/:nr_set/:position/(/:code)', to: 'printings#show', as: 'printing'

  get '/card_images/:nr_set/:code', to: 'images#serve', as: 'image'
end
