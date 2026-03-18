Rails.application.routes.draw do
  resources :products

  # Defines the root path route ("/")
  root "products#index"
end
