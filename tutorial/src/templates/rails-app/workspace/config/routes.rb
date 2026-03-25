Rails.application.routes.draw do
  resource :session do
    post :preauthenticate, on: :collection
  end

  resources :tickets do
    resources :comments, only: [:create, :destroy]
  end

  # Defines the root path route ("/")
  root "home#index"
end
