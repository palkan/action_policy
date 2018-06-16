Rails.application.routes.draw do
  namespace :groups do
    resources :announcements
  end
end
