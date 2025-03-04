# Helper module for creating valid test locations
module PlacekeyTestHelper
  # Create a test location with a valid Placekey
  def create_test_location(attributes = {})
    location = Location.new({
      name: "Test Location",
      latitude: 37.7749,
      longitude: -122.4194
    }.merge(attributes))

    # Only set a placekey if not explicitly set to nil
    if !attributes.has_key?(:placekey)
      # Generate a valid Placekey format
      # Using the newer without-location format: "@xxx-xxx-xxx"
      location.placekey = "@5vg-7gq-tvz"
    end

    # Skip validation to ensure the record is saved regardless
    location.save(validate: false)

    location
  end

  # For creating multiple locations in a batch
  def create_test_locations(count, base_attributes = {})
    locations = []

    count.times do |i|
      attributes = base_attributes.merge(
        name: "#{base_attributes[:name] || 'Test Location'} #{i}",
        latitude: (base_attributes[:latitude] || 37.7749) + (i * 0.01),
        longitude: (base_attributes[:longitude] || -122.4194) - (i * 0.01)
      )

      # Generate a unique but valid Placekey for each location
      # Format: @xxx-xxx-xxx
      placekey = "@#{format('%03d', i)}-7gq-tvz"

      location = Location.new(attributes)
      location.placekey = placekey
      location.save(validate: false)

      locations << location
    end

    locations
  end

  # Create a grid of test locations
  def create_location_grid(width, height, base_lat = 37.75, base_lng = -122.45)
    locations = []

    width.times do |x|
      height.times do |y|
        location = Location.new(
          name: "Grid #{x},#{y}",
          latitude: base_lat + (x * 0.01),
          longitude: base_lng + (y * 0.01)
        )

        # Generate a valid grid-based Placekey
        location.placekey = "@#{format('%03d', x)}-#{format('%03d', y)}-xyz"
        location.save(validate: false)

        locations << location
      end
    end

    locations
  end

  # Create a location that will consistently fail in batch processing
  def create_failing_test_location(attributes = {})
    location = Location.new({
      name: "Failing Test Location",
      latitude: nil,
      longitude: nil
    }.merge(attributes))

    # Save without validation
    location.save(validate: false)

    location
  end
end

RSpec.configure do |config|
  config.include PlacekeyTestHelper
end
