# PlacekeyRails Quick Start Guide

This guide will help you get started with PlacekeyRails in a new or existing Rails application.

## Installation

1. Add the gem to your Gemfile:

```ruby
gem 'placekey_rails', '~> 0.2.0'
```

2. Install dependencies:

```bash
bundle install
```

3. Install system dependencies:

```bash
# macOS
brew install cmake h3

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install cmake
git clone https://github.com/uber/h3.git
cd h3
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON .
make
sudo make install
```

## Basic Usage

### Setup API Client (if needed)

```ruby
# config/initializers/placekey.rb
PlacekeyRails.setup_client(ENV['PLACEKEY_API_KEY'])
```

### Convert Coordinates to Placekey

```ruby
placekey = PlacekeyRails.geo_to_placekey(37.7371, -122.44283)
# => "@5vg-82n-kzz"
```

### Convert Placekey to Coordinates

```ruby
lat, long = PlacekeyRails.placekey_to_geo("@5vg-82n-kzz")
# => [37.7371, -122.44283]
```

## ActiveRecord Integration

### 1. Add Placekey Column to Your Model

```ruby
# Create migration
rails g migration AddPlacekeyToLocations placekey:string

# In the migration file
class AddPlacekeyToLocations < ActiveRecord::Migration[7.0]
  def change
    add_column :locations, :placekey, :string
    add_index :locations, :placekey
  end
end

# Run migration
rails db:migrate
```

### 2. Add Placekeyable Concern to Your Model

```ruby
# app/models/location.rb
class Location < ApplicationRecord
  include PlacekeyRails::Concerns::Placekeyable
  
  # Your model should have:
  # - latitude (float)
  # - longitude (float)
  # - placekey (string)
end
```

Now your model will:
- Automatically generate placekeys from coordinates
- Validate placekey format
- Provide spatial query methods

### 3. Use Spatial Queries

```ruby
# Find locations within 500 meters of a placekey
nearby = Location.within_distance("@5vg-82n-kzz", 500)

# Find locations within 1 km of coordinates
nearby = Location.near_coordinates(37.7371, -122.44283, 1000)
```

## View Helpers

### 1. Include Helpers in Your Controller

```ruby
# app/controllers/locations_controller.rb
class LocationsController < ApplicationController
  helper PlacekeyRails::PlacekeyHelper
  helper PlacekeyRails::FormHelper
end
```

### 2. Display Placekeys in Views

```erb
<%# Format a placekey %>
<%= format_placekey(@location.placekey) %>

<%# Display a placekey on a map %>
<%= leaflet_map_for_placekey(@location.placekey, height: "300px") %>

<%# Create a placekey card %>
<%= placekey_card(@location.placekey, title: "Store Location") %>
```

### 3. Create Forms with Placekey Fields

```erb
<%= form_with(model: @location) do |form| %>
  <%# Basic placekey field %>
  <%= placekey_field(form) %>
  
  <%# Coordinate fields that auto-generate placekey %>
  <%= placekey_coordinate_fields(form) %>
  
  <%# Address fields with API lookup %>
  <%= placekey_address_fields(form) %>
  
  <%= form.submit %>
<% end %>
```

## JavaScript Integration

### 1. Add JavaScript to Your Application

```javascript
// app/javascript/application.js
import "placekey_rails"
```

### 2. Include Required CSS (for Tailwind users)

```javascript
// app/javascript/application.js
import "placekey_rails/css"
```

## Next Steps

- Read the [full documentation](API_REFERENCE.md) for detailed API reference
- Explore [examples](EXAMPLES.md) for more advanced usage patterns
- Look at [troubleshooting](TROUBLESHOOTING.md) if you encounter issues
