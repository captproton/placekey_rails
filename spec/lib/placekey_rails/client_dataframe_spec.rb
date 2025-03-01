require 'rails_helper'

# Create a dummy DataFrame class for testing
module Rover
  class DataFrame
    # Define proper initialization method with data argument
    def initialize(data = nil)
      # This is just a mock constructor
    end

    # Define methods to match what we'll be mocking
    def [](key); end
    def []=(key, value); end
    def has_column?(column); end
    def join(other, options = {}); end
    def delete(column); end
    def rename(mapping); end
    def each_row_with_index; end
  end
end

RSpec.describe PlacekeyRails::Client, "DataFrame Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { described_class.new(api_key) }
  let(:logger) { instance_double(ActiveSupport::Logger, info: nil, error: nil) }

  # Create mock data and DataFrame directly
  let(:row_data) do
    [
      { 'lat' => 37.7371, 'lng' => -122.44283, 'address' => '123 Main St' },
      { 'lat' => 37.7373, 'lng' => -122.44284, 'address' => '456 Oak Ave' }
    ]
  end

  let(:dataframe) do
    # Use double instead of instance_double to avoid method verification
    df = double("Rover::DataFrame")

    # Set up basic behaviors
    allow(df).to receive(:[]) { df }
    allow(df).to receive(:[]=)
    allow(df).to receive(:has_column?) { true }
    allow(df).to receive(:join) { df }
    allow(df).to receive(:delete) { df }
    allow(df).to receive(:rename) { df }

    # Set up row iteration
    allow(df).to receive(:each_row_with_index) do |&block|
      row_data.each_with_index do |data, i|
        row = double("Row")
        allow(row).to receive(:[]) { |key| data[key] }
        block.call(row, i)
      end
    end

    df
  end

  # Create a mock for the result DataFrame
  let(:result_df) do
    df = double("Rover::DataFrame")
    allow(df).to receive(:rename) { df }
    df
  end

  before do
    allow(client).to receive(:logger).and_return(logger)

    # Handle DataFrame.new with results
    allow(Rover::DataFrame).to receive(:new) do |arg|
      if arg.is_a?(Array)
        # Return our result_df when called with array data
        result_df
      else
        # Otherwise return the regular dataframe
        dataframe
      end
    end
  end

  describe "#placekey_dataframe" do
    let(:column_mapping) do
      {
        'latitude' => 'lat',
        'longitude' => 'lng',
        'street_address' => 'address'
      }
    end

    it "validates minimum inputs" do
      invalid_mapping = { 'street_address' => 'address' } # Missing required fields
      expect { client.placekey_dataframe(dataframe, invalid_mapping) }.to raise_error(ArgumentError, /doesn't have enough information/)
    end

    it "prepares data for API requests" do
      expect(client).to receive(:lookup_placekeys) do |places, *args|
        expect(places.size).to eq(2)
        expect(places[0]['latitude']).to eq(37.7371)
        expect(places[0]['longitude']).to eq(-122.44283)
        expect(places[0]['street_address']).to eq('123 Main St')

        # Return mock results
        [
          { 'query_id' => 'place_0', 'placekey' => '@5vg-82n-kzz' },
          { 'query_id' => 'place_1', 'placekey' => '@5vg-82n-kyz' }
        ]
      end

      result = client.placekey_dataframe(dataframe, column_mapping)
      expect(result).to eq(dataframe) # Should return the joined dataframe
    end

    it "handles API errors gracefully" do
      expect(client).to receive(:lookup_placekeys) do |places, *args|
        # Return error results
        [
          { 'query_id' => 'place_0', 'error' => 'Invalid coordinates' },
          { 'query_id' => 'place_1', 'error' => 'Invalid coordinates' }
        ]
      end

      # Should not raise an error
      expect { client.placekey_dataframe(dataframe, column_mapping) }.not_to raise_error
    end

    it "uses verbose mode correctly" do
      expect(client).to receive(:lookup_placekeys) do |places, fields, batch_size, verbose|
        expect(verbose).to be true
        []
      end

      client.placekey_dataframe(dataframe, column_mapping, nil, 100, true)
    end
  end
end
