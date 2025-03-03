require 'spec_helper'

RSpec.describe PlacekeyRails::BatchProcessor do
  let(:processor) { described_class.new }
  let(:logger) { double('logger', info: nil, error: nil) }
  let(:processor_with_logger) { described_class.new(logger: logger) }

  # Simple record class for testing
  let(:record_class) do
    Class.new do
      attr_accessor :id, :placekey, :latitude, :longitude,
                    :street_address, :city, :region, :postal_code, :country_code,
                    :address, :town, :state, :lat, :lng

      def initialize(attrs = {})
        attrs.each do |k, v|
          send("#{k}=", v) if respond_to?("#{k}=")
        end
        @id ||= rand(1000)
      end

      def save
        true
      end

      def update(attrs)
        attrs.each do |k, v|
          send("#{k}=", v) if respond_to?("#{k}=")
        end
        true
      end
    end
  end

  let(:collection) do
    [
      record_class.new(latitude: 37.7371, longitude: -122.44283),
      record_class.new(latitude: 37.7372, longitude: -122.44284),
      record_class.new(street_address: '123 Main St', city: 'San Francisco', region: 'CA')
    ]
  end

  let(:active_record_collection) do
    collection_double = double('ActiveRecord::Relation')
    allow(collection_double).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
    allow(collection_double).to receive(:find_in_batches).and_yield(collection)
    allow(collection_double).to receive(:count).and_return(collection.size)
    allow(collection_double).to receive(:where).and_return(collection)
    allow(collection_double).to receive(:select).and_return(collection.select { |r| true })
    collection_double
  end

  before do
    stub_const("ActiveRecord::Relation", Class.new)

    allow(PlacekeyRails).to receive(:geo_to_placekey).and_return('@5vg-7gq-tvz')
    allow(PlacekeyRails).to receive(:placekey_distance).and_return(100)
    allow(PlacekeyRails).to receive(:get_neighboring_placekeys).and_return([ '@5vg-7gq-tvz', '@5vg-7gq-tvy' ])
    allow(PlacekeyRails).to receive(:default_client).and_return(double('client'))
    allow(PlacekeyRails).to receive(:lookup_placekey).and_return({
      'placekey' => '@5vg-7gq-tvz'
    })
  end

  describe '#process' do
    it 'processes a collection in batches' do
      operation = ->(record) {
        record.placekey = '@5vg-7gq-tvz'
        true
      }

      result = processor.process(collection, operation)
      expect(result[:processed]).to eq(3)
      expect(result[:successful]).to eq(3)
      expect(collection.first.placekey).to eq('@5vg-7gq-tvz')
    end

    it 'handles errors gracefully' do
      # Make one record always fail
      record_with_error = collection[1]

      operation = ->(record) {
        if record == record_with_error
          raise "Test error"
        end
        record.placekey = '@5vg-7gq-tvz'
        true
      }

      result = processor_with_logger.process(collection, operation)
      expect(result[:processed]).to eq(3)
      expect(result[:successful]).to eq(2)
      expect(result[:errors].size).to eq(1)
      expect(logger).to have_received(:error).at_least(:once)
    end

    it 'works with ActiveRecord::Relation' do
      operation = ->(record) { true }

      # Patch the process_in_batches method for this test
      allow_any_instance_of(PlacekeyRails::BatchProcessor).to receive(:process_in_batches).and_yield(collection)

      result = processor.process(active_record_collection, operation)
      expect(result[:processed]).to eq(3)
      expect(result[:successful]).to eq(3)
    end

    it 'calls the progress block after each batch' do
      operation = ->(record) { true }

      block_called = false
      processor.process(collection, operation) do |processed, successful|
        block_called = true
        expect(processed).to eq(3)
        expect(successful).to eq(3)
      end

      expect(block_called).to be true
    end
  end

  describe '#geocode' do
    it 'geocodes records with addresses' do
      record = record_class.new(street_address: '123 Main St', city: 'San Francisco', region: 'CA')

      result = processor.geocode([ record ])
      expect(result[:successful]).to eq(1)
      expect(record.placekey).to eq('@5vg-7gq-tvz')
    end

    it 'generates placekeys from coordinates if available' do
      record = record_class.new(latitude: 37.7371, longitude: -122.44283)

      result = processor.geocode([ record ])
      expect(result[:successful]).to eq(1)
      expect(record.placekey).to eq('@5vg-7gq-tvz')
    end

    it 'skips records that already have placekeys' do
      record = record_class.new(placekey: '@existing')

      result = processor.geocode([ record ])
      expect(result[:successful]).to eq(0)
      expect(record.placekey).to eq('@existing')
    end

    it 'uses custom address field mapping' do
      # Create a record with custom field names
      record = record_class.new
      record.address = '123 Main St'
      record.town = 'San Francisco'
      record.state = 'CA'

      mapping = {
        street_address: :address,
        city: :town,
        region: :state
      }

      result = processor.geocode([ record ], mapping)
      expect(result[:successful]).to eq(1)
      expect(record.placekey).to eq('@5vg-7gq-tvz')
    end
  end

  describe '#generate_placekeys' do
    it 'generates placekeys from coordinates' do
      record = record_class.new(latitude: 37.7371, longitude: -122.44283)

      result = processor.generate_placekeys([ record ])
      expect(result[:successful]).to eq(1)
      expect(record.placekey).to eq('@5vg-7gq-tvz')
    end

    it 'skips records without coordinates' do
      record = record_class.new

      result = processor.generate_placekeys([ record ])
      expect(result[:successful]).to eq(0)
      expect(record.placekey).to be_nil
    end

    it 'uses custom coordinate field names' do
      # Create a record with custom coordinate field names
      record = record_class.new
      record.lat = 37.7371
      record.lng = -122.44283

      result = processor.generate_placekeys([ record ], lat_field: :lat, lng_field: :lng)
      expect(result[:successful]).to eq(1)
      expect(record.placekey).to eq('@5vg-7gq-tvz')
    end
  end

  describe '#find_nearby' do
    it 'finds records within the specified distance' do
      records = [
        record_class.new(placekey: '@record1'),
        record_class.new(placekey: '@record2'),
        record_class.new(placekey: '@record3')
      ]

      # Mock the neighbor_keys retrieval to include all records
      allow(PlacekeyRails).to receive(:get_neighboring_placekeys).and_return(records.map(&:placekey))

      results = processor_with_logger.find_nearby(records, 37.7371, -122.44283, 200)
      expect(results.size).to eq(3)
    end

    it 'filters out records beyond the distance' do
      close_record = record_class.new(placekey: '@record1')
      far_record = record_class.new(placekey: '@record2')
      records = [ close_record, far_record ]

      # Mock the neighbor_keys retrieval to include all records
      allow(PlacekeyRails).to receive(:get_neighboring_placekeys).and_return(records.map(&:placekey))

      # Mock the distance calculation to make one record too far
      allow(PlacekeyRails).to receive(:placekey_distance).with(anything, '@record1').and_return(100)
      allow(PlacekeyRails).to receive(:placekey_distance).with(anything, '@record2').and_return(300)

      results = processor.find_nearby(records, 37.7371, -122.44283, 200)
      expect(results.size).to eq(1)
      expect(results.first).to eq(close_record)
    end

    it 'works with ActiveRecord::Relation' do
      # Create records with placekeys
      records = [
        record_class.new(placekey: '@record1'),
        record_class.new(placekey: '@record2')
      ]

      # Mock the ActiveRecord behavior
      relation = double('ActiveRecord::Relation')
      allow(relation).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
      allow(relation).to receive(:where).and_return(records)

      # Mock the neighbor_keys retrieval to include all records
      allow(PlacekeyRails).to receive(:get_neighboring_placekeys).and_return(records.map(&:placekey))

      results = processor.find_nearby(relation, 37.7371, -122.44283, 200)
      expect(results.size).to eq(2)
    end
  end
end
