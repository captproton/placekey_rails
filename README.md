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

## Documentation

For detailed documentation, please see:

- [API Reference](docs/API_REFERENCE.md) - Complete reference for all gem methods
- [Examples](docs/EXAMPLES.md) - Detailed examples of using the gem
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
