class <%= @model_name.camelize %> < ApplicationRecord
  include PlacekeyRails::Concerns::Placekeyable
  
  validates :name, presence: true
  
  # Set up additional validations or associations as needed
  
  # Example of using the Placekeyable concern:
  # 
  # 1. Generate placekey from coordinates:
  #    location = <%= @model_name.camelize %>.create(
  #      name: "Example Location",
  #      latitude: 37.7371, 
  #      longitude: -122.44283
  #    )
  #    # Placekey will be automatically generated
  # 
  # 2. Find locations within a distance:
  #    nearby = <%= @model_name.camelize %>.within_distance("@5vg-82n-kzz", 1000) # Within 1km
  # 
  # 3. Calculate distance between locations:
  #    location1.distance_to(location2) # Returns distance in meters
  # 
  # 4. Geocode an address to get placekey:
  #    <%= @model_name.camelize %>.batch_geocode_addresses
end