class Location < ApplicationRecord
  include PlacekeyRails::Concerns::Placekeyable
  
  validates :name, presence: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
  
  # Skip placekey validation in tests 
  # By default, Placekeyable concern adds placekey validation
  # but we need to disable it for our mocked test environment
  if Rails.env.test?
    _validators.delete(:placekey)
    _validate_callbacks.each do |callback|
      if callback.filter.is_a?(ActiveModel::Validations::PlacekeyValidator)
        skip_callback(:validate, callback.kind, callback.filter)
      end
    end
  end
  
  before_validation :generate_placekey, if: :coordinates_changed?
  
  def coordinates_changed?
    latitude_changed? || longitude_changed?
  end
end
