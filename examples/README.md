# PlacekeyRails Example Application

This directory contains examples of how to integrate and use the PlacekeyRails gem in a Rails application.

## Setup Instructions

To integrate PlacekeyRails in your application:

1. Add the gem to your Gemfile:

```ruby
gem 'placekey_rails'
```

2. Run bundle install:

```bash
bundle install
```

3. Mount the engine in your routes.rb file:

```ruby
Rails.application.routes.draw do
  mount PlacekeyRails::Engine => '/placekey'
  
  # Your other routes...
end
```

4. Initialize the Placekey API client in an initializer (if you'll be using the API):

```ruby
# config/initializers/placekey.rb
PlacekeyRails.setup_client(ENV['PLACEKEY_API_KEY']) if ENV['PLACEKEY_API_KEY'].present?
```

5. Set up the JavaScript components in your application.js:

```javascript
// app/javascript/application.js
import { Application } from "@hotwired/stimulus"
import { definitionsFromContext } from "@hotwired/stimulus-webpack-helpers"

// Import PlacekeyRails Stimulus controllers
import { controllerDefinitions } from "placekey_rails"

const application = Application.start()

// Register your application's controllers
const context = require.context("./controllers", true, /\.js$/)
application.load(definitionsFromContext(context))

// Register PlacekeyRails controllers
application.load(controllerDefinitions)
```

## Examples

### 1. Creating a Model with Placekey Support

```ruby
# app/models/location.rb
class Location < ApplicationRecord
  include PlacekeyRails::Concerns::Placekeyable
  
  validates :name, presence: true
  validates :latitude, :longitude, numericality: true, allow_nil: true
end
```

### 2. Creating a Form with Placekey Fields

```erb
<%# app/views/locations/_form.html.erb %>
<%= form_with(model: location) do |form| %>
  <div class="field">
    <%= form.label :name %>
    <%= form.text_field :name %>
  </div>

  <div class="field">
    <%= form.label :description %>
    <%= form.text_area :description %>
  </div>
  
  <h3>Location Details</h3>
  
  <%# Using placekey_coordinate_fields helper %>
  <%= placekey_coordinate_fields(form) %>
  
  <div class="actions">
    <%= form.submit %>
  </div>
<% end %>
```

### 3. Displaying a Placekey on a Show Page

```erb
<%# app/views/locations/show.html.erb %>
<h1><%= @location.name %></h1>

<p><%= @location.description %></p>

<% if @location.placekey.present? %>
  <h3>Location Information</h3>
  
  <%# Using placekey_card helper %>
  <%= placekey_card(@location.placekey) do %>
    <p>
      <%= external_map_link_for_placekey(@location.placekey) %>
    </p>
  <% end %>
<% end %>
```

### 4. Finding Nearby Locations in a Controller

```ruby
# app/controllers/locations_controller.rb
class LocationsController < ApplicationController
  def nearby
    @origin = Location.find(params[:id])
    distance = params[:distance].to_i || 1000 # meters
    
    @nearby_locations = Location.within_distance(@origin.placekey, distance)
    
    respond_to do |format|
      format.html
      format.json { render json: @nearby_locations }
    end
  end
  
  def search_area
    # Search by drawing a polygon on a map
    geojson = JSON.parse(params[:geojson])
    @locations = Location.within_geojson(geojson)
    
    render json: @locations
  end
end
```

### 5. Address Lookup Form

```erb
<%# app/views/locations/lookup.html.erb %>
<h1>Find Location by Address</h1>

<%= form_with(model: @location, url: lookup_locations_path) do |form| %>
  <%# Using placekey_address_fields helper %>
  <%= placekey_address_fields(form) %>
  
  <div class="actions">
    <%= form.submit "Save Location" %>
  </div>
<% end %>
```

### 6. Batch Geocoding Locations

```ruby
# A rake task to batch geocode locations
namespace :locations do
  desc "Geocode all locations without placekeys"
  task geocode: :environment do
    result = Location.batch_geocode_addresses do |processed, successful|
      puts "Processed #{processed} locations (#{successful} successful)"
    end
    
    puts "Finished processing #{result[:processed]} locations (#{result[:successful]} successful)"
  end
end
```

## Sample Database Schema

```ruby
# Example migration for a locations table
class CreateLocations < ActiveRecord::Migration[7.0]
  def change
    create_table :locations do |t|
      t.string :name, null: false
      t.text :description
      t.string :street_address
      t.string :city
      t.string :region
      t.string :postal_code
      t.string :iso_country_code
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :placekey, index: true
      
      t.timestamps
    end
  end
end
```

## Performance Tips

1. Add an index on the placekey column for faster spatial queries:

```ruby
add_index :locations, :placekey
```

2. Use batch_geocode_addresses for processing many records efficiently:

```ruby
Location.batch_geocode_addresses(batch_size: 50)
```

3. Use caching for frequent API lookups:

```ruby
# config/initializers/placekey.rb
PlacekeyRails.setup_client(ENV['PLACEKEY_API_KEY'], max_retries: 3)
PlacekeyRails.enable_caching(max_size: 1000)
```

4. For very large datasets, consider implementing background jobs for geocoding:

```ruby
# app/jobs/geocode_location_job.rb
class GeocodeLocationJob < ApplicationJob
  queue_as :default
  
  def perform(location_id)
    location = Location.find(location_id)
    return if location.placekey.present?
    
    if location.coordinates_available?
      location.generate_placekey
      location.save
    elsif location.street_address.present?
      result = PlacekeyRails.lookup_placekey(
        street_address: location.street_address,
        city: location.city,
        region: location.region,
        postal_code: location.postal_code
      )
      
      if result && result["placekey"].present?
        location.update(placekey: result["placekey"])
      end
    end
  end
end
```
