# ActiveRecord Integration

This document explains how to integrate PlacekeyRails with your ActiveRecord models.

## The Placekeyable Concern

The `Placekeyable` concern is the primary way to add Placekey functionality to your models. It provides validations, callbacks, and methods for working with Placekeys.

### Basic Usage

```ruby
# app/models/location.rb
class Location < ApplicationRecord
  include PlacekeyRails::Concerns::Placekeyable
  
  # Your model should have these fields:
  # - latitude (float)
  # - longitude (float)
  # - placekey (string)
end
```

This automatically adds:
- Validations for Placekey format
- Automatic generation of Placekeys from coordinates
- Scopes and instance methods for working with Placekeys

### Requirements

Your model should have these columns:
- `latitude` (float)
- `longitude` (float)
- `placekey` (string)

To add the `placekey` column to an existing model:

```ruby
class AddPlacekeyToLocations < ActiveRecord::Migration[7.0]
  def change
    add_column :locations, :placekey, :string
    add_index :locations, :placekey
  end
end
```

### Features

#### Automatic Placekey Generation

When a record with coordinates but no Placekey is saved, a Placekey will be automatically generated:

```ruby
location = Location.new(latitude: 37.7371, longitude: -122.44283)
location.save
location.placekey # => "@5vg-82n-kzz"
```

#### Placekey Validation

Placekeys are validated for proper format:

```ruby
location = Location.new(placekey: "invalid-format")
location.valid? # => false
location.errors[:placekey] # => ["is not a valid Placekey format"]
```

#### Geographic Conversion Methods

Convert between Placekeys and coordinates:

```ruby
# Get coordinates from a Placekey
location = Location.find_by(placekey: "@5vg-82n-kzz")
lat, lng = location.placekey_to_geo
# => [37.7371, -122.44283]

# Get the H3 index
h3_index = location.placekey_to_h3
# => "8a2830828767fff"

# Get the boundary coordinates
boundary = location.placekey_boundary
# => [[37.775, -122.443], [37.774, -122.441], ...]

# Get as GeoJSON
geojson = location.placekey_to_geojson
```

#### Finding Neighboring Locations

```ruby
# Get neighboring placekeys
neighbors = location.neighboring_placekeys(distance: 1)
# => Set of Placekey strings

# Find records with those placekeys
neighboring_locations = Location.where(placekey: neighbors)
```

#### Calculate Distances

```ruby
# Calculate distance to another location
other_location = Location.find(123)
distance_in_meters = location.distance_to(other_location)

# Or directly to a placekey
distance_in_meters = location.distance_to("@5vg-82n-kzz")
```

### Scopes and Class Methods

#### Finding Records By Distance

```ruby
# Find locations within 500 meters of a placekey
nearby = Location.within_distance("@5vg-82n-kzz", 500)

# Find locations within 500 meters of coordinates
nearby = Location.near_coordinates(37.7371, -122.44283, 500)
```

#### Finding Records Within Geographic Areas

```ruby
# Find locations within a GeoJSON polygon
within_area = Location.within_geojson(geojson_data)

# Find locations within a WKT polygon
within_area = Location.within_wkt(wkt_string)
```

#### Batch Geocoding

If your records have addresses but no Placekeys, you can batch geocode them:

```ruby
# First ensure the API client is set up
PlacekeyRails.setup_client("your-api-key")

# Then batch geocode (defaults to 100 records per batch)
results = Location.batch_geocode_addresses

# With progress updates
Location.batch_geocode_addresses do |processed, successful|
  puts "Processed #{processed} records, #{successful} successful"
end

# With custom field mappings
Location.batch_geocode_addresses(
  address_field: :street,
  city_field: :town,
  region_field: :state
)
```

## Custom Integration

If you don't want to use the concern, you can integrate manually:

```ruby
class CustomLocation < ApplicationRecord
  before_validation :generate_placekey, if: -> { latitude.present? && longitude.present? && placekey.blank? }
  
  validates :placekey, format: { 
    with: /\A(@[23456789bcdfghjkmnpqrstvwxyzeu]{3}-[23456789bcdfghjkmnpqrstvwxyzeu]{3}-[23456789bcdfghjkmnpqrstvwxyzeu]{3}|[23456789bcdfghjkmnpqrstvwxyz]+-[23456789bcdfghjkmnpqrstvwxyz]+@[23456789bcdfghjkmnpqrstvwxyzeu]{3}-[23456789bcdfghjkmnpqrstvwxyzeu]{3}-[23456789bcdfghjkmnpqrstvwxyzeu]{3})\z/,
    message: "is not a valid Placekey format"
  }, allow_blank: true
  
  private
  
  def generate_placekey
    self.placekey = PlacekeyRails.geo_to_placekey(latitude, longitude)
  end
end
```
