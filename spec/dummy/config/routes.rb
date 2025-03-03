Rails.application.routes.draw do
  get "dummy_rails7_testing/index"

  # Mount the Placekey Engine
  mount PlacekeyRails::Engine => "/placekey_rails"

  # Routes for Location resources
  resources :locations do
    collection do
      post :batch_process
    end
  end

  # Root route
  root to: 'locations#index'
end
