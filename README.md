# PlacekeyRails

[![Gem Version](https://badge.fury.io/rb/placekey_rails.svg)](https://badge.fury.io/rb/placekey_rails)
[![CI](https://github.com/captproton/placekey_rails/actions/workflows/ci.yml/badge.svg)](https://github.com/captproton/placekey_rails/actions/workflows/ci.yml)

A Ruby on Rails engine for working with [Placekeys](https://placekey.io/) - a universal standard identifier for physical places.

## What is Placekey?

Placekey is a free, universal standard identifier for any physical place. It's designed to work across datasets and organizations, making it easier to join and analyze location data.

A Placekey has two parts:
- The **what** part (optional): identifies a specific POI or address within a location
- The **where** part (required): identifies the physical location's hexagon on a global grid (based on H3)

Example: `227@5vg-82n-kzz` where `227` is the "what" and `@5vg-82n-kzz` is the "where"

## Features

- Convert between geographic coordinates and Placekeys
- Convert between H3 indices and Placekeys
- Validate Placekey formats
- Find neighboring Placekeys
- Calculate distances between Placekeys
- Convert Placekeys to various geographic formats (GeoJSON, WKT, Polygons)
- Find Placekeys within geographic areas
- Interface with the Placekey API for lookups
- Process dataframes with Placekey data
- ActiveRecord integration with model concerns
- View helpers for displaying and working with Placekeys
- JavaScript components for interactive Placekey maps and forms
- Built-in caching and batch processing for performance optimization

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'placekey_rails'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install placekey_rails
```

## Requirements

The gem requires:
- Ruby >= 3.2.0
- Rails >= 8.0.1
- CMake (for H3 installation)
- H3 library

### Installing System Dependencies

#### macOS

```bash
brew install cmake
brew install h3
```

#### Ubuntu/Debian

```bash
sudo apt-get update
sudo apt-get install cmake
# H3 requires manual installation from source
git clone https://github.com/uber/h3.git
cd h3
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON .
make
sudo make install
```

## Basic Usage

### Conversion Between Coordinates and Placekeys

```ruby
require 'placekey_rails'

# Convert latitude and longitude to a Placekey
placekey = PlacekeyRails.geo_to_placekey(37.7371, -122.44283)
# => "@5vg-82n-kzz"

# Convert a Placekey back to coordinates
lat, long = PlacekeyRails.placekey_to_geo("@5vg-82n-kzz")
# => [37.7371, -122.44283]
```

### H3 Conversions

Convert between H3 indices and Placekeys:

```ruby
# Convert an H3 index to a Placekey
placekey = PlacekeyRails.h3_to_placekey("8a2830828767fff")
# => "@5vg-7gq-tvz"

# Convert a Placekey to an H3 index
h3_index = PlacekeyRails.placekey_to_h3("@5vg-7gq-tvz")
# => "8a2830828767fff"
```

### Validation

Check if a Placekey has valid format:

```ruby
PlacekeyRails.placekey_format_is_valid("@5vg-7gq-tvz")
# => true

PlacekeyRails.placekey_format_is_valid("invalid-format")
# => false
```

### Spatial Operations

Calculate distance and find neighboring Placekeys:

```ruby
# Calculate distance between two Placekeys in meters
distance = PlacekeyRails.placekey_distance("@5vg-7gq-tvz", "@5vg-82n-kzz")
# => 1242.8

# Find neighboring Placekeys within a given grid distance
neighbors = PlacekeyRails.get_neighboring_placekeys("@5vg-7gq-tvz", 1)
# Returns a set of Placekeys including the input and all immediate neighbors
```

### API Client

Use the API client to look up Placekeys for addresses or coordinates:

```ruby
# Initialize the client with your API key
PlacekeyRails.setup_client("your-api-key")

# Look up a Placekey by address
result = PlacekeyRails.lookup_placekey({
  street_address: "598 Portola Dr",
  city: "San Francisco",
  region: "CA",
  postal_code: "94131"
})
# => {"placekey" => "@5vg-82n-pgk", ...}

# Look up multiple places in a batch
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

results = PlacekeyRails.lookup_placekeys(places)
```

## ActiveRecord Integration

Add Placekey functionality to your models:

```ruby
# app/models/location.rb
class Location < ApplicationRecord
  include PlacekeyRails::Concerns::Placekeyable
  
  # Now your model has:
  # - Automatic Placekey generation from coordinates
  # - Placekey validation
  # - Spatial query methods
end

# Find locations within 500 meters of a Placekey
nearby = Location.within_distance("@5vg-82n-kzz", 500)

# Find locations within a geographic area
within_area = Location.within_geojson(geojson_data)

# Batch geocode locations
Location.batch_geocode_addresses
```

## View Helpers

Use the included helpers to display Placekeys in your views:

```erb
<%# Format a Placekey for display %>
<%= format_placekey("abc-123@5vg-82n-kzz") %>

<%# Display a Placekey on a map %>
<%= leaflet_map_for_placekey(@location.placekey) %>

<%# Generate a Placekey card with map %>
<%= placekey_card(@location.placekey, title: "Store Location") %>

<%# Create an address form with Placekey lookup %>
<%= form_with(model: @location) do |form| %>
  <%= placekey_address_fields(form) %>
  <%= form.submit %>
<% end %>
```

## JavaScript Components

The gem includes Stimulus.js controllers for interactive Placekey functionality:

- `placekey-map` - Displays a Placekey on a Leaflet map
- `placekey-generator` - Automatically generates a Placekey from coordinates
- `placekey-lookup` - Looks up a Placekey from an address
- `placekey-preview` - Shows a preview map for a Placekey

Simply include the JavaScript in your application:

```javascript
// app/javascript/application.js
import "placekey_rails"
```

## Performance Optimization

PlacekeyRails includes various performance optimization features:

### Built-in Caching

```ruby
# Enable caching to reduce API calls
PlacekeyRails.enable_caching(max_size: 1000)

# Clear the cache when needed
PlacekeyRails.clear_cache
```

### Batch Processing

```ruby
# Process multiple records efficiently
result = PlacekeyRails.batch_geocode(Location.where(placekey: nil), batch_size: 100)

# With progress reporting
PlacekeyRails.batch_geocode(Location.where(placekey: nil)) do |processed, successful|
  puts "Processed #{processed} locations (#{successful} successful)"
end
```

For more performance tips, see the [Performance Optimization Guide](docs/PERFORMANCE.md).

## Documentation

For detailed documentation, please see:

- [API Reference](docs/API_REFERENCE.md) - Complete reference for all gem methods
- [Examples](docs/EXAMPLES.md) - Detailed examples of using the gem
- [ActiveRecord Integration](docs/ACTIVERECORD_INTEGRATION.md) - Using with models
- [View Helpers](docs/VIEW_HELPERS.md) - Helpers for views and forms
- [JavaScript Components](docs/JAVASCRIPT_COMPONENTS.md) - Using the JS components
- [Performance Optimization](docs/PERFORMANCE.md) - Tips for optimizing performance
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Solutions for common issues

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

### Running Tests

```bash
bundle exec rspec
```

### Generating Documentation

```bash
bundle exec yard
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b feature/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-new-feature`)
5. Create a new Pull Request

Bug reports and pull requests are welcome on GitHub at https://github.com/captproton/placekey_rails.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Acknowledgments

- This gem is inspired by the [Placekey Python library](https://github.com/placekey/placekey-py)
- Built with Ruby on Rails and the H3 spatial indexing system from Uber
