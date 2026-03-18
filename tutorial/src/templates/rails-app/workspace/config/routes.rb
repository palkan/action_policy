Rails.application.routes.draw do
  resource :session do
    post :preauthenticate, on: :collection
  end

  # Defines the root path route ("/")
  root "home#index"
end
