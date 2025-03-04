# PlacekeyRails Example Application Blueprint

## Overview

This Rails application demonstrates the key features of the PlacekeyRails gem in a practical context. It allows users to manage location data with Placekeys, view locations on maps, and perform spatial queries.

## Features

- CRUD operations for Location records
- Automatic Placekey generation from coordinates
- Address geocoding to generate Placekeys
- Interactive maps with Placekey hexagons
- Spatial queries to find nearby locations
- Batch processing of location data

## Structure

### Models

```ruby
# app/models/location.rb
class Location < ApplicationRecord
  include PlacekeyRails::Concerns::Placekeyable
  
  validates :name, presence: true
  validates :latitude, :longitude, numericality: true, allow_nil: true
  
  # Example scope to find featured locations
  scope :featured, -> { where(featured: true) }
end
```

### Controllers

```ruby
# app/controllers/locations_controller.rb
class LocationsController < ApplicationController
  helper PlacekeyRails::PlacekeyHelper
  helper PlacekeyRails::FormHelper
  
  def index
    @locations = Location.all
    @map_data = placekeys_map_data(@locations.pluck(:placekey))
  end
  
  def show
    @location = Location.find(params[:id])
  end
  
  def new
    @location = Location.new
  end
  
  def create
    @location = Location.new(location_params)
    
    if @location.save
      redirect_to @location, notice: "Location was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    @location = Location.find(params[:id])
  end
  
  def update
    @location = Location.find(params[:id])
    
    if @location.update(location_params)
      redirect_to @location, notice: "Location was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @location = Location.find(params[:id])
    @location.destroy
    
    redirect_to locations_url, notice: "Location was successfully destroyed."
  end
  
  def nearby
    @location = Location.find(params[:id])
    @distance = params[:distance].to_i || 1000 # Default 1km
    
    @nearby_locations = Location.within_distance(@location.placekey, @distance)
    @map_data = placekeys_map_data(@nearby_locations.pluck(:placekey) + [@location.placekey])
  end
  
  def address_lookup
    @location = Location.new
  end
  
  def batch_geocode
    @locations = Location.where(placekey: nil).limit(10)
  end
  
  def perform_batch_geocode
    result = Location.batch_geocode_addresses
    
    redirect_to locations_url, notice: "Processed #{result[:processed]} locations (#{result[:successful]} successful)"
  end
  
  private
  
  def location_params
    params.require(:location).permit(
      :name, :description, :featured,
      :street_address, :city, :region, :postal_code, :iso_country_code,
      :latitude, :longitude, :placekey
    )
  end
end
```

### Views

Layouts for:
1. Index page showing all locations on a map
2. Show page with location details and map
3. New/Edit forms with different input options:
   - Basic Placekey input
   - Coordinate fields
   - Address fields
4. Nearby locations view showing distance-based queries
5. Batch processing interface

### JavaScript

```javascript
// app/javascript/application.js
import Rails from "@rails/ujs"
import Turbo from "@hotwired/turbo"
import { Application } from "@hotwired/stimulus"

// Import PlacekeyRails JavaScript
import "placekey_rails"

Rails.start()
Turbo.start()

const application = Application.start()
// ... register controllers
```

### CSS

Include the PlacekeyRails CSS styles (from the VIEW_HELPERS.md document)

### Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  resources :locations do
    member do
      get :nearby
    end
    
    collection do
      get :address_lookup
      get :batch_geocode
      post :perform_batch_geocode
    end
  end
  
  root "locations#index"
end
```

### Initializers

```ruby
# config/initializers/placekey.rb
PlacekeyRails.setup_client(ENV['PLACEKEY_API_KEY']) if ENV['PLACEKEY_API_KEY'].present?
PlacekeyRails.enable_caching(max_size: 100) # Implement caching
```

## Implementation

This application will be implemented as a separate Rails application that depends on the PlacekeyRails gem. The code examples above provide the blueprint for implementation.

Once implemented, we'll use this application to:
1. Generate the required screenshots
2. Test performance optimizations
3. Demonstrate all gem features in a cohesive manner
