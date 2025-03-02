# PlacekeyRails Examples

This document provides detailed examples of using the PlacekeyRails gem in various scenarios.

## Table of Contents

- [Basic Conversion Examples](#basic-conversion-examples)
- [Validation Examples](#validation-examples)
- [Spatial Operation Examples](#spatial-operation-examples)
- [API Client Examples](#api-client-examples)
- [Integration with Rails](#integration-with-rails)

## Basic Conversion Examples

### Converting Between Coordinates and Placekeys

```ruby
require 'placekey_rails'

# Convert latitude and longitude to a Placekey
placekey = PlacekeyRails.geo_to_placekey(37.7371, -122.44283)
puts placekey
# => "@5vg-82n-kzz"

# Convert a Placekey back to coordinates
lat, long = PlacekeyRails.placekey_to_geo("@5vg-82n-kzz")
puts "Latitude: #{lat}, Longitude: #{long}"
# => Latitude: 37.7371, Longitude: -122.44283
```

### Converting Between H3 and Placekeys

```ruby
# Convert an H3 index to a Placekey
h3_string = "8a2830828767fff"
placekey = PlacekeyRails.h3_to_placekey(h3_string)
puts placekey
# => "@5vg-7gq-tvz"

# Convert a Placekey to an H3 index
placekey = "@5vg-7gq-tvz"
h3_index = PlacekeyRails.placekey_to_h3(placekey)
puts h3_index
# => "8a2830828767fff"
```

### Parsing Placekeys

```ruby
# Parse a Placekey into its components
placekey = "abc-123@5vg-7gq-tvz"
what, where = PlacekeyRails::Converter.parse_placekey(placekey)
puts "What: #{what}, Where: #{where}"
# => What: abc-123, Where: 5vg-7gq-tvz

# Handle a Placekey with only a 'where' part
placekey = "@5vg-7gq-tvz"
what, where = PlacekeyRails::Converter.parse_placekey(placekey)
puts "What: #{what.nil? ? 'None' : what}, Where: #{where}"
# => What: None, Where: 5vg-7gq-tvz
```

## Validation Examples

### Checking Placekey Format Validity

```ruby
# Valid Placekey with only 'where' part
valid = PlacekeyRails.placekey_format_is_valid("@5vg-7gq-tvz")
puts "Is valid: #{valid}"
# => Is valid: true

# Valid Placekey with both 'what' and 'where' parts
valid = PlacekeyRails.placekey_format_is_valid("abc-123@5vg-7gq-tvz")
puts "Is valid: #{valid}"
# => Is valid: true

# Invalid Placekey with malformed 'where' part
valid = PlacekeyRails.placekey_format_is_valid("@5vg-7gq")
puts "Is valid: #{valid}"
# => Is valid: false

# Invalid Placekey with malformed 'what' part
valid = PlacekeyRails.placekey_format_is_valid("ab@5vg-7gq-tvz")
puts "Is valid: #{valid}"
# => Is valid: false
```

## Spatial Operation Examples

### Finding Neighboring Placekeys

```ruby
# Get neighboring Placekeys with distance 1
placekey = "@5vg-7gq-tvz"
neighbors = PlacekeyRails.get_neighboring_placekeys(placekey, 1)
puts "Number of neighbors: #{neighbors.size}"
puts "Neighbors: #{neighbors.to_a}"
# => Number of neighbors: 7
# => Neighbors: ["@5vg-7gq-tvz", "@5vg-7gq-tuz", ...]

# Get neighboring Placekeys with distance 2
neighbors = PlacekeyRails.get_neighboring_placekeys(placekey, 2)
puts "Number of neighbors: #{neighbors.size}"
# => Number of neighbors: 19
```

### Calculating Distance Between Placekeys

```ruby
placekey1 = "@5vg-7gq-tvz"
placekey2 = "@5vg-82n-kzz"
distance = PlacekeyRails.placekey_distance(placekey1, placekey2)
puts "Distance: #{distance} meters"
# => Distance: 1242.8 meters
```

### Getting Hexagon Boundaries

```ruby
placekey = "@5vg-7gq-tvz"

# Get the boundary in lat/long format
boundary = PlacekeyRails.placekey_to_hex_boundary(placekey)
puts "Boundary points: #{boundary.size}"
puts "First point: #{boundary.first}"
# => Boundary points: 6
# => First point: [37.775, -122.443]

# Get the boundary in GeoJSON format (long/lat)
geojson_boundary = PlacekeyRails.placekey_to_hex_boundary(placekey, true)
puts "First point: #{geojson_boundary.first}"
# => First point: [-122.443, 37.775]
```

### Working with Polygons

```ruby
placekey = "@5vg-7gq-tvz"

# Convert Placekey to a polygon
polygon = PlacekeyRails.placekey_to_polygon(placekey)
puts "Polygon type: #{polygon.class}"
# => Polygon type: RGeo::Cartesian::PolygonImpl

# Convert Placekey to WKT
wkt = PlacekeyRails.placekey_to_wkt(placekey)
puts "WKT: #{wkt[0..50]}..."
# => WKT: POLYGON((37.775 -122.443, 37.774 -122.441, 37.772 -1...

# Convert Placekey to GeoJSON
geojson = PlacekeyRails.placekey_to_geojson(placekey)
puts "GeoJSON type: #{geojson['type']}"
puts "Geometry type: #{geojson['geometry']['type']}"
# => GeoJSON type: Feature
# => Geometry type: Polygon
```

### Finding Placekeys Within a Geographic Area

```ruby
# Start with a WKT polygon
wkt_polygon = "POLYGON((-122.45 37.78, -122.43 37.78, -122.43 37.76, -122.45 37.76, -122.45 37.78))"

# Find Placekeys within the polygon
result = PlacekeyRails.wkt_to_placekeys(wkt_polygon)
puts "Interior Placekeys: #{result[:interior].size}"
puts "Boundary Placekeys: #{result[:boundary].size}"
# => Interior Placekeys: 10
# => Boundary Placekeys: 8

# Same with a GeoJSON polygon
geojson_polygon = {
  "type" => "Feature",
  "geometry" => {
    "type" => "Polygon",
    "coordinates" => [
      [
        [-122.45, 37.78],
        [-122.43, 37.78],
        [-122.43, 37.76],
        [-122.45, 37.76],
        [-122.45, 37.78]
      ]
    ]
  }
}

result = PlacekeyRails.geojson_to_placekeys(geojson_polygon)
puts "Interior Placekeys: #{result[:interior].size}"
puts "Boundary Placekeys: #{result[:boundary].size}"
# => Interior Placekeys: 10
# => Boundary Placekeys: 8
```

## API Client Examples

### Setting Up the Client

```ruby
# Configure the client with your API key
PlacekeyRails.setup_client("your-api-key")

# Or create a client instance directly
client = PlacekeyRails::Client.new("your-api-key", max_retries: 5)
```

### Looking Up a Single Placekey

```ruby
# First set up the client
PlacekeyRails.setup_client("your-api-key")

# Look up a Placekey by address
result = PlacekeyRails.lookup_placekey({
  street_address: "598 Portola Dr",
  city: "San Francisco",
  region: "CA",
  postal_code: "94131"
})
puts "Placekey: #{result['placekey']}"
# => Placekey: 227-223@5vg-82n-pgk

# Look up a Placekey by coordinates
result = PlacekeyRails.lookup_placekey({
  latitude: 37.7371,
  longitude: -122.44283
})
puts "Placekey: #{result['placekey']}"
# => Placekey: @5vg-82n-kzz
```

### Looking Up Multiple Placekeys

```ruby
# First set up the client
PlacekeyRails.setup_client("your-api-key")

# Create an array of places
places = [
  {
    street_address: "1543 Mission Street, Floor 3",
    city: "San Francisco",
    region: "CA",
    postal_code: "94105"
  },
  {
    latitude: 37.7371,
    longitude: -122.44283
  }
]

# Look up Placekeys for all places
results = PlacekeyRails.lookup_placekeys(places)
results.each_with_index do |result, i|
  puts "Place #{i+1} Placekey: #{result['placekey']}"
end
# => Place 1 Placekey: 22g@5vg-7gq-5mk
# => Place 2 Placekey: @5vg-82n-kzz
```

### Working with DataFrames

```ruby
require 'rover-df'

# First set up the client
PlacekeyRails.setup_client("your-api-key")

# Create a DataFrame with location data
data = [
  { address: "1543 Mission St", city: "San Francisco", state: "CA", zip: "94105" },
  { address: "598 Portola Dr", city: "San Francisco", state: "CA", zip: "94131" }
]
df = Rover::DataFrame.new(data)

# Define the column mapping
column_mapping = {
  "street_address" => "address",
  "city" => "city",
  "region" => "state",
  "postal_code" => "zip"
}

# Process the DataFrame to get Placekeys
result_df = PlacekeyRails.placekey_dataframe(df, column_mapping)
puts "Result columns: #{result_df.column_names}"
# => Result columns: ["address", "city", "state", "zip", "placekey", ...]

# Use the Placekeys for analysis
result_df.each_row do |row|
  puts "Address: #{row['address']}, Placekey: #{row['placekey']}"
end
```

## Integration with Rails

### Using in a Rails Model

```ruby
# app/models/location.rb
class Location < ApplicationRecord
  validates :placekey, presence: true, if: :coordinates_present?
  
  before_validation :generate_placekey, if: :coordinates_present?
  
  def coordinates_present?
    latitude.present? && longitude.present?
  end
  
  private
  
  def generate_placekey
    return if placekey.present?
    self.placekey = PlacekeyRails.geo_to_placekey(latitude, longitude)
  end
end
```

### Creating a Concern for Placekey Support

```ruby
# app/models/concerns/placekey_support.rb
module PlacekeySupport
  extend ActiveSupport::Concern
  
  included do
    validates :placekey, presence: true, if: :should_have_placekey?
    before_validation :generate_placekey, if: :should_generate_placekey?
    
    scope :within_distance, ->(placekey, distance_meters) {
      placekeys = nearby_placekeys(placekey, distance_meters)
      where(placekey: placekeys)
    }
  end
  
  def should_have_placekey?
    respond_to?(:latitude) && respond_to?(:longitude) && 
      latitude.present? && longitude.present?
  end
  
  def should_generate_placekey?
    should_have_placekey? && placekey.blank?
  end
  
  def generate_placekey
    self.placekey = PlacekeyRails.geo_to_placekey(latitude, longitude)
  end
  
  def hex_boundary
    PlacekeyRails.placekey_to_hex_boundary(placekey)
  end
  
  def to_geojson
    PlacekeyRails.placekey_to_geojson(placekey)
  end
  
  module ClassMethods
    def nearby_placekeys(placekey, distance_meters)
      # Get potential neighbors within grid distance 2
      neighbors = PlacekeyRails.get_neighboring_placekeys(placekey, 2)
      
      # Filter by actual distance
      neighbors.select do |pk|
        PlacekeyRails.placekey_distance(placekey, pk) <= distance_meters
      end
    end
    
    def geocode_addresses
      return unless PlacekeyRails.default_client
      
      uncoded = where(placekey: nil).where.not(street_address: nil)
      records = []
      
      uncoded.find_in_batches(batch_size: 100) do |group|
        places = group.map do |record|
          {
            street_address: record.street_address,
            city: record.city,
            region: record.region,
            postal_code: record.postal_code,
            query_id: record.id.to_s
          }
        end
        
        results = PlacekeyRails.lookup_placekeys(places)
        
        results.each do |result|
          if result['placekey'].present?
            record = uncoded.find(result['query_id'])
            record.update(placekey: result['placekey'])
          end
        end
      end
    end
  end
end
```

### Using with ActiveRecord Migrations

```ruby
class AddPlacekeyToLocations < ActiveRecord::Migration[7.0]
  def change
    add_column :locations, :placekey, :string
    add_index :locations, :placekey, unique: true
  end
end
```

### Creating a Helper for Maps

```ruby
# app/helpers/placekey_helper.rb
module PlacekeyHelper
  def placekey_to_map_data(placekey)
    return {} unless placekey.present?
    
    # Get geographic information
    lat, lng = PlacekeyRails.placekey_to_geo(placekey)
    boundary = PlacekeyRails.placekey_to_hex_boundary(placekey, true)
    
    {
      center: { lat: lat, lng: lng },
      boundary: boundary,
      geojson: PlacekeyRails.placekey_to_geojson(placekey)
    }
  end
  
  def placekeys_collection_to_map_data(placekeys)
    return [] if placekeys.blank?
    
    placekeys.map do |pk|
      placekey_to_map_data(pk)
    end
  end
end
```

### Using in a Controller

```ruby
# app/controllers/locations_controller.rb
class LocationsController < ApplicationController
  include PlacekeyHelper
  
  def index
    @locations = Location.all
    @map_data = placekeys_collection_to_map_data(@locations.pluck(:placekey))
    
    respond_to do |format|
      format.html
      format.json { render json: @map_data }
    end
  end
  
  def show
    @location = Location.find(params[:id])
    @map_data = placekey_to_map_data(@location.placekey)
    
    respond_to do |format|
      format.html
      format.json { render json: @map_data }
    end
  end
  
  def nearby
    @location = Location.find(params[:id])
    
    distance_meters = params[:distance].to_i || 500
    placekeys = Location.nearby_placekeys(@location.placekey, distance_meters)
    
    @nearby_locations = Location.where(placekey: placekeys)
                               .where.not(id: @location.id)
    
    @map_data = placekeys_collection_to_map_data(@nearby_locations.pluck(:placekey))
    @map_data.unshift(placekey_to_map_data(@location.placekey))
    
    respond_to do |format|
      format.html
      format.json { render json: @map_data }
    end
  end
end
```

### Using in a View with JavaScript

```erb
<!-- app/views/locations/show.html.erb -->
<div id="map" style="height: 400px; width: 100%;"></div>

<script>
  document.addEventListener('DOMContentLoaded', function() {
    const mapData = <%= raw @map_data.to_json %>;
    
    // Initialize a map (using Leaflet as an example)
    const map = L.map('map').setView([mapData.center.lat, mapData.center.lng], 15);
    
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap contributors'
    }).addTo(map);
    
    // Add the hexagon to the map
    const hexagonCoords = mapData.boundary.map(coord => [coord[1], coord[0]]);
    L.polygon(hexagonCoords, {
      color: 'blue',
      fillColor: '#3388ff',
      fillOpacity: 0.4,
      weight: 2
    }).addTo(map);
    
    // Add a marker at the center
    L.marker([mapData.center.lat, mapData.center.lng])
      .addTo(map)
      .bindPopup('Placekey: <%= @location.placekey %>');
  });
</script>
```

### Using with Stimulus.js

```javascript
// app/javascript/controllers/placekey_map_controller.js
import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

export default class extends Controller {
  static targets = ["container"]
  static values = {
    placekey: String,
    lat: Number,
    lng: Number,
    boundary: Array
  }
  
  connect() {
    if (!this.hasLatValue || !this.hasLngValue) {
      this.fetchPlacekeyData()
    } else {
      this.initializeMap()
    }
  }
  
  fetchPlacekeyData() {
    if (!this.hasPlacekeyValue) return
    
    fetch(`/api/placekeys/${this.placekeyValue}`)
      .then(response => response.json())
      .then(data => {
        this.latValue = data.center.lat
        this.lngValue = data.center.lng
        this.boundaryValue = data.boundary
        this.initializeMap()
      })
  }
  
  initializeMap() {
    if (!this.hasContainerTarget) return
    
    this.map = L.map(this.containerTarget).setView([this.latValue, this.lngValue], 15)
    
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap contributors'
    }).addTo(this.map)
    
    if (this.hasBoundaryValue) {
      const hexagonCoords = this.boundaryValue.map(coord => [coord[1], coord[0]])
      L.polygon(hexagonCoords, {
        color: 'blue',
        fillColor: '#3388ff',
        fillOpacity: 0.4,
        weight: 2
      }).addTo(this.map)
    }
    
    L.marker([this.latValue, this.lngValue])
      .addTo(this.map)
      .bindPopup(`Placekey: ${this.placekeyValue}`)
  }
  
  disconnect() {
    if (this.map) {
      this.map.remove()
    }
  }
}
```

```erb
<!-- app/views/locations/show.html.erb -->
<div data-controller="placekey-map" 
     data-placekey-map-placekey-value="<%= @location.placekey %>"
     data-placekey-map-lat-value="<%= @location.latitude %>"
     data-placekey-map-lng-value="<%= @location.longitude %>"
     data-placekey-map-boundary-value="<%= @map_data[:boundary].to_json %>">
  <div data-placekey-map-target="container" style="height: 400px; width: 100%;"></div>
</div>
```
