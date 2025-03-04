# PlacekeyRails Compatibility Guide

This document outlines the compatibility of PlacekeyRails with different versions of Ruby, Rails, and other dependencies.

## Version Compatibility Matrix

| PlacekeyRails Version | Ruby Version       | Rails Version       | H3 Gem Version | Notes                                         |
|-----------------------|--------------------|---------------------|----------------|-----------------------------------------------|
| 0.1.0                 | >= 3.2.0           | >= 8.0.1            | ~> 3.7.2       | Initial release                               |
| 0.2.0                 | >= 3.2.0           | >= 8.0.1            | ~> 3.7.2       | Added Rails integration features              |

## Ruby Compatibility

PlacekeyRails requires Ruby 3.2.0 or later due to:
- Use of modern Ruby syntax features
- Dependency on gems that require Ruby 3.2+
- Performance optimizations using Ruby 3.2+ features

## Rails Compatibility

PlacekeyRails requires Rails 8.0.1 or later due to:
- Integration with modern Rails features
- Use of Rails 8.0 ActiveSupport features
- Tailwind CSS integration requirements

## H3 Library Compatibility

The gem requires the H3 library version 3.7.2 or compatible. This is provided through the h3-ruby gem, which wraps the C implementation of the H3 library.

## JavaScript Dependencies

For the JavaScript components to work correctly, the following are required:
- Stimulus.js 2.0+
- Turbo 7.0+
- Tailwind CSS 3.0+
- Leaflet.js for map functionality

## Operating System Support

The gem has been tested on:
- macOS Monterey (12.0+)
- macOS Ventura (13.0+)
- Ubuntu 20.04 LTS
- Ubuntu 22.04 LTS
- Debian 11 (Bullseye)

Limited support is available for:
- Windows (via WSL) 
- CentOS/RHEL 8+

## Cloud Platform Support

The gem has been tested and confirmed working on:
- Heroku (with appropriate buildpacks)
- DigitalOcean App Platform (with configuration)
- AWS Elastic Beanstalk
- Railway.app

## Unsupported Environments

The following environments are not officially supported:
- Ruby implementations other than MRI (e.g., JRuby, TruffleRuby)
- Rails versions below 8.0
- Ruby versions below 3.2.0
- Windows without WSL

## Testing Your Environment

To verify that your environment is compatible, run the following after installation:

```ruby
require 'placekey_rails'

# Test basic conversion functionality
placekey = PlacekeyRails.geo_to_placekey(37.7371, -122.44283)
puts "Conversion to Placekey: #{placekey}"

# Test H3 integration
h3_index = PlacekeyRails.placekey_to_h3(placekey)
puts "Conversion to H3: #{h3_index}"

# If using Rails, test ActiveRecord integration
if defined?(Rails)
  puts "Rails version: #{Rails.version}"
  puts "PlacekeyRails config: #{PlacekeyRails.config.inspect}"
end
```

If all of these tests pass, your environment should be compatible with PlacekeyRails.
