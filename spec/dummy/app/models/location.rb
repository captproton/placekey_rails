class Location < ApplicationRecord
  include PlacekeyRails::Concerns::Placekeyable
  
  validates :name, presence: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
  
  before_validation :generate_placekey, if: :coordinates_changed?
  
  def coordinates_changed?
    latitude_changed? || longitude_changed?
  end
end
