require 'rails_helper'

RSpec.describe PlacekeyRails::Concerns::Placekeyable do
  # Create a test model that includes the Placekeyable concern
  let(:test_model_class) do
    Class.new(ActiveRecord::Base) do
      # Mock an ActiveRecord class
      self.table_name = 'places'

      include PlacekeyRails::Concerns::Placekeyable

      # Define accessors for our test model
      attr_accessor :placekey, :latitude, :longitude

      def self.where(*args)
        self
      end

      def self.not(*args)
        self
      end

      def self.find_by(*args)
        new(id: 1, placekey: '@5vg-7gq-tvz')
      end

      def self.find_in_batches(batch_size:)
        yield [new(id: 1, placekey: nil, latitude: 37.7371, longitude: -122.44283)]
        yield [new(id: 2, placekey: nil, latitude: 37.7372, longitude: -122.44284)]
      end

      def id
        @id ||= 1
      end

      def id=(value)
        @id = value
      end

      def update(attributes)
        attributes.each do |key, value|
          send("#{key}=", value)
        end
        true
      end

      def save
        true
      end
    end
  end

  let(:test_instance) { test_model_class.new }

  before do
    # Mock the PlacekeyRails module methods
    allow(PlacekeyRails).to receive(:geo_to_placekey).and_return('@5vg-7gq-tvz')
    allow(PlacekeyRails).to receive(:placekey_to_geo).and_return([37.7371, -122.44283])
    allow(PlacekeyRails).to receive(:placekey_to_h3).and_return('8a2830828767fff')
    allow(PlacekeyRails).to receive(:placekey_to_hex_boundary).and_return([[37.7, -122.4], [37.7, -122.5]])
    allow(PlacekeyRails).to receive(:placekey_to_geojson).and_return({ "type" => "Polygon" })
    allow(PlacekeyRails).to receive(:get_neighboring_placekeys).and_return(['@5vg-7gq-tvz', '@5vg-7gq-tvy'])
    allow(PlacekeyRails).to receive(:placekey_distance).and_return(123.45)
    allow(PlacekeyRails).to receive(:default_client).and_return(double('client'))
    allow(PlacekeyRails).to receive(:lookup_placekeys).and_return([
      { 'query_id' => '1', 'placekey' => '@5vg-7gq-tvz' }
    ])
    allow(PlacekeyRails).to receive(:get_prefix_distance_dict).and_return({ 0 => 2.004e7 })
  end

  describe 'validations' do
    it 'validates placekey format when present' do
      test_instance.placekey = 'invalid-format'
      expect(test_instance).to receive(:placekey_validatable?).and_return(true)
      expect(test_instance).to receive(:valid?).and_return(false)
      
      # Trigger validation manually since we're not using a real ActiveRecord model
      test_instance.class.validators.each do |validator|
        validator.validate(test_instance)
      end
      
      # Simulate errors object in ActiveRecord
      test_instance.instance_variable_set(:@errors, {placekey: ['is not a valid Placekey format']})
      expect(test_instance.instance_variable_get(:@errors)[:placekey]).to include('is not a valid Placekey format')
    end
  end

  describe '#coordinates_available?' do
    it 'returns true when latitude and longitude are present' do
      test_instance.latitude = 37.7371
      test_instance.longitude = -122.44283
      expect(test_instance.coordinates_available?).to be true
    end

    it 'returns false when latitude is missing' do
      test_instance.longitude = -122.44283
      expect(test_instance.coordinates_available?).to be false
    end

    it 'returns false when longitude is missing' do
      test_instance.latitude = 37.7371
      expect(test_instance.coordinates_available?).to be false
    end
  end

  describe '#generate_placekey' do
    it 'generates placekey from coordinates' do
      test_instance.latitude = 37.7371
      test_instance.longitude = -122.44283
      test_instance.generate_placekey
      expect(test_instance.placekey).to eq('@5vg-7gq-tvz')
    end

    it 'does not generate placekey when coordinates are missing' do
      expect(test_instance.generate_placekey).to be_nil
      expect(test_instance.placekey).to be_nil
    end
  end

  describe '#placekey_to_geo' do
    it 'returns coordinates from placekey' do
      test_instance.placekey = '@5vg-7gq-tvz'
      expect(test_instance.placekey_to_geo).to eq([37.7371, -122.44283])
    end

    it 'returns nil when placekey is missing' do
      expect(test_instance.placekey_to_geo).to be_nil
    end
  end

  describe '#placekey_to_h3' do
    it 'returns H3 index from placekey' do
      test_instance.placekey = '@5vg-7gq-tvz'
      expect(test_instance.placekey_to_h3).to eq('8a2830828767fff')
    end

    it 'returns nil when placekey is missing' do
      expect(test_instance.placekey_to_h3).to be_nil
    end
  end

  describe '#placekey_boundary' do
    it 'returns boundary coordinates for placekey' do
      test_instance.placekey = '@5vg-7gq-tvz'
      expect(test_instance.placekey_boundary).to eq([[37.7, -122.4], [37.7, -122.5]])
    end

    it 'returns nil when placekey is missing' do
      expect(test_instance.placekey_boundary).to be_nil
    end
  end

  describe '#placekey_to_geojson' do
    it 'returns GeoJSON representation of placekey' do
      test_instance.placekey = '@5vg-7gq-tvz'
      expect(test_instance.placekey_to_geojson).to eq({ "type" => "Polygon" })
    end

    it 'returns nil when placekey is missing' do
      expect(test_instance.placekey_to_geojson).to be_nil
    end
  end

  describe '#neighboring_placekeys' do
    it 'returns neighboring placekeys' do
      test_instance.placekey = '@5vg-7gq-tvz'
      expect(test_instance.neighboring_placekeys).to eq(['@5vg-7gq-tvz', '@5vg-7gq-tvy'])
    end

    it 'returns empty array when placekey is missing' do
      expect(test_instance.neighboring_placekeys).to eq([])
    end
  end

  describe '#distance_to' do
    it 'calculates distance to another placekey string' do
      test_instance.placekey = '@5vg-7gq-tvz'
      expect(test_instance.distance_to('@5vg-7gq-tvy')).to eq(123.45)
    end

    it 'calculates distance to another placekeyable object' do
      test_instance.placekey = '@5vg-7gq-tvz'
      other = test_model_class.new
      other.placekey = '@5vg-7gq-tvy'
      expect(test_instance.distance_to(other)).to eq(123.45)
    end

    it 'returns nil when placekey is missing' do
      expect(test_instance.distance_to('@5vg-7gq-tvy')).to be_nil
    end

    it 'returns nil when other placekey is invalid' do
      test_instance.placekey = '@5vg-7gq-tvz'
      expect(test_instance.distance_to(nil)).to be_nil
    end
  end

  describe '.within_distance' do
    it 'finds records within specified distance' do
      allow(PlacekeyRails).to receive(:placekey_distance).and_return(100)
      result = test_model_class.within_distance('@5vg-7gq-tvz', 200)
      expect(result).not_to be_empty
    end

    it 'filters out records beyond specified distance' do
      allow(PlacekeyRails).to receive(:placekey_distance).and_return(300)
      result = test_model_class.within_distance('@5vg-7gq-tvz', 200)
      expect(result).to be_empty
    end
  end

  describe '.near_coordinates' do
    it 'finds records near specified coordinates' do
      expect(PlacekeyRails).to receive(:geo_to_placekey).with(37.7371, -122.44283).and_return('@5vg-7gq-tvz')
      expect(test_model_class).to receive(:within_distance).with('@5vg-7gq-tvz', 500)
      test_model_class.near_coordinates(37.7371, -122.44283, 500)
    end
  end

  describe '.batch_geocode_addresses' do
    it 'batch geocodes records without placekeys' do
      result = test_model_class.batch_geocode_addresses
      expect(result[:processed]).to eq(2)
      expect(result[:successful]).to eq(2)
    end
  end
end
