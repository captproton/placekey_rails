require 'rails_helper'

# Make sure Rover::DataFrame is properly defined for testing
unless defined?(Rover) && defined?(Rover::DataFrame)
  module Rover
    class DataFrame
      # Define methods we'll need for mocking
      def [](key); end
      def []=(key, value); end
      def has_column?(column); end
      def join(other, options={}); end
      def delete(column); end
      def rename(mapping); end
      def each_row_with_index; end
    end
  end
end

RSpec.describe PlacekeyRails, "Module API Client Methods" do
  let(:api_key) { "test_api_key" }
  let(:mock_client) { instance_double(PlacekeyRails::Client) }
  
  before do
    # Save and restore the default client to avoid modifying it between tests
    @original_client = PlacekeyRails.instance_variable_get(:@default_client)
    PlacekeyRails.instance_variable_set(:@default_client, mock_client)
  end
  
  after do
    # Restore original client
    PlacekeyRails.instance_variable_set(:@default_client, @original_client)
  end
  
  describe ".setup_client" do
    it "initializes a new client" do
      expect(PlacekeyRails::Client).to receive(:new).with(api_key, { max_retries: 10 }).and_return(mock_client)
      PlacekeyRails.setup_client(api_key, max_retries: 10)
    end
  end
  
  describe ".lookup_placekey" do
    let(:params) { { 'latitude' => 37.7371, 'longitude' => -122.44283 } }
    let(:expected_result) { { 'placekey' => '@5vg-82n-kzz' } }
    
    it "delegates to the default client" do
      expect(mock_client).to receive(:lookup_placekey).with(params, nil).and_return(expected_result)
      result = PlacekeyRails.lookup_placekey(params)
      expect(result).to eq(expected_result)
    end
    
    it "raises an error if client not set up" do
      # Simulate no client being set up
      PlacekeyRails.instance_variable_set(:@default_client, nil)
      
      expect { PlacekeyRails.lookup_placekey(params) }.to raise_error(PlacekeyRails::Error, /Default API client not set up/)
    end
  end
  
  describe ".lookup_placekeys" do
    let(:places) do
      [
        { 'latitude' => 37.7371, 'longitude' => -122.44283 },
        { 'street_address' => '598 Portola Dr', 'city' => 'San Francisco', 'region' => 'CA', 'postal_code' => '94131' }
      ]
    end
    
    let(:expected_results) do
      [
        { 'query_id' => 'place_0', 'placekey' => '@5vg-82n-kzz' },
        { 'query_id' => 'place_1', 'placekey' => '227-223@5vg-82n-pgk' }
      ]
    end
    
    it "delegates to the default client with default parameters" do
      expect(mock_client).to receive(:lookup_placekeys).with(places, nil, 100, false).and_return(expected_results)
      results = PlacekeyRails.lookup_placekeys(places)
      expect(results).to eq(expected_results)
    end
    
    it "passes custom parameters correctly" do
      expect(mock_client).to receive(:lookup_placekeys).with(places, ['address_placekey'], 50, true).and_return(expected_results)
      PlacekeyRails.lookup_placekeys(places, ['address_placekey'], 50, true)
    end
  end
  
  describe ".placekey_dataframe" do
    let(:dataframe) { double("Rover::DataFrame") }
    let(:column_mapping) { { 'latitude' => 'lat', 'longitude' => 'lng' } }
    
    it "delegates to the default client with default parameters" do
      expect(mock_client).to receive(:placekey_dataframe).with(dataframe, column_mapping, nil, 100, false).and_return(dataframe)
      result = PlacekeyRails.placekey_dataframe(dataframe, column_mapping)
      expect(result).to eq(dataframe)
    end
    
    it "passes custom parameters correctly" do
      expect(mock_client).to receive(:placekey_dataframe).with(dataframe, column_mapping, ['address_placekey'], 50, true).and_return(dataframe)
      PlacekeyRails.placekey_dataframe(dataframe, column_mapping, ['address_placekey'], 50, true)
    end
  end
end
