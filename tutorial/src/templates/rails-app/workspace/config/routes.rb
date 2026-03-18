Rails.application.routes.draw do
  resource :session

  # Defines the root path route ("/")
  root "home#index"
end
