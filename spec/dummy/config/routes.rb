Rails.application.routes.draw do
  get "dummy_rails7_testing/index"
  mount PlacekeyRails::Engine => "/placekey_rails"
end
