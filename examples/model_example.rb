# Example of a Location model using the Placekeyable concern
class Location < ApplicationRecord
  include PlacekeyRails::Concerns::Placekeyable

  validates :name, presence: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true

  # Example scope to find locations with a specific tag and placekey
  scope :tagged_with, ->(tag) { where("tags LIKE ?", "%#{tag}%").with_placekey }

  # Find locations within a specified radius of coordinates
  def self.near(lat, lng, radius_meters = 1000)
    near_coordinates(lat, lng, radius_meters)
  end

  # Calculate distance to another location
  def distance_to_location(other_location)
    return nil unless placekey.present? && other_location&.placekey.present?
    distance_to(other_location)
  end

  # Find neighboring locations
  def neighboring_locations(distance = 1)
    return [] unless placekey.present?
    neighbors = neighboring_placekeys(distance)
    Location.where(placekey: neighbors)
  end

  # Get GeoJSON representation for mapping
  def to_geojson
    return nil unless placekey.present?

    # Get the polygon geometry from the placekey
    geometry = placekey_to_geojson

    # Create a GeoJSON feature with properties
    {
      type: "Feature",
      geometry: geometry,
      properties: {
        id: id,
        name: name,
        placekey: placekey
      }
    }
  end

  # Geocode the location using its address
  def geocode!
    return if placekey.present? || !address_available?

    result = PlacekeyRails.lookup_placekey(
      street_address: street_address,
      city: city,
      region: region,
      postal_code: postal_code,
      iso_country_code: country_code
    )

    if result && result["placekey"].present?
      update(placekey: result["placekey"])

      # If we don't have coordinates, derive them from the placekey
      if !coordinates_available? && placekey.present?
        lat, lng = placekey_to_geo
        update(latitude: lat, longitude: lng)
      end

      true
    else
      false
    end
  end

  private

  def address_available?
    street_address.present? &&
      ((city.present? && region.present?) || postal_code.present?)
  end
end
