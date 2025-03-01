# PlacekeyRails

A Ruby on Rails engine that provides functionality for working with Placekeys - a universal standard identifier for physical places.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'placekey_rails'
```

And then execute:

```
$ bundle install
```

Or install it yourself as:

```
$ gem install placekey_rails
```

## Requirements

The gem requires:
- Ruby >= 3.2.0
- Rails >= 8.0.1
- CMake (for H3 installation)
- H3 library

## Usage

### Basic Conversions

Convert between geographic coordinates and Placekeys:

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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/captproton/placekey_rails.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).