require 'rails_helper'

# Mock Rover::DataFrame for testing
module Rover
  class DataFrame
    # This is just a mock class for testing
  end
end

RSpec.describe PlacekeyRails::Client, "DataFrame Integration" do
  let(:api_key) { "test_api_key" }
  let(:client) { described_class.new(api_key) }
  let(:logger) { instance_double(ActiveSupport::Logger, info: nil, error: nil) }
  
  # Mock Rover::DataFrame for testing
  let(:dataframe) do
    df = instance_double(Rover::DataFrame)
    allow(df).to receive(:[]).and_return(df)
    allow(df).to receive(:[]=)
    allow(df).to receive(:has_column?).and_return(true)
    allow(df).to receive(:join).and_return(df)
    allow(df).to receive(:delete).and_return(df)
    allow(df).to receive(:rename).and_return(df)
    
    # Create a method for each_row_with_index that yields a row and index
    row_data = [
      { 'lat' => 37.7371, 'lng' => -122.44283, 'address' => '123 Main St' },
      { 'lat' => 37.7373, 'lng' => -122.44284, 'address' => '456 Oak Ave' }
    ]
    
    allow(df).to receive(:each_row_with_index) do |&block|
      row_data.each_with_index do |row, i|
        row_obj = instance_double("Rover::DataFrame::Row")
        allow(row_obj).to receive(:[]) { |key| row[key] }
        block.call(row_obj, i)
      end
    end
    
    df
  end

  before do
    allow(client).to receive(:logger).and_return(logger)
    allow(Rover::DataFrame).to receive(:new).and_return(dataframe)
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
