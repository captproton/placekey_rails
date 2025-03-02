PlacekeyRails::Engine.routes.draw do
  root to: "home#index"
  
  # API routes
  namespace :api do
    resources :placekeys, only: [:show] do
      collection do
        post :from_coordinates
        post :from_address
      end
    end
  end
end
