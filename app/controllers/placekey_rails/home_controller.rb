module PlacekeyRails
  class HomeController < ApplicationController
    def index
      render plain: 'Placekey Rails Engine'
    end
  end
end
