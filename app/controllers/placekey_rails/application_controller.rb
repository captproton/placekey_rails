module PlacekeyRails
  class ApplicationController < ActionController::Base
    layout 'placekey_rails/application'
    protect_from_forgery with: :exception
  end
end