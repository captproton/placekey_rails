require 'rails_helper'

RSpec.describe "Complete Placekey Workflow", type: :integration do
  # We'll test the complete workflow from:
  # 1. Creating a model with Placekeyable concern
  # 2. Using form helpers to input coordinates
  # 3. Processing the data with the BatchProcessor
  # 4. Displaying results on a map
  
  let(:test_locations) do
    [
      { name: "San Francisco", latitude: 37.7749, longitude: -122.4194 },
      { name: "New York", latitude: 40.7128, longitude: -74.0060 },
      { name: "Los Angeles", latitude: 34.0522, longitude: -118.2437 }
    ]
  end
  
  before do
    # Set up API client and module mocks
    mock_placekey_api_client
    mock_placekey_module
    
    # Make sure the database is clean
    Location.destroy_all
  end
  
  describe "Basic Placekeyable functionality" do
    it "automatically generates a placekey when coordinates are provided" do
      location = Location.create!(
        name: "San Francisco", 
        latitude: 37.7749, 
        longitude: -122.4194
      )
      
      expect(location.placekey).to eq("@37--122-xyz")
    end
    
    it "provides spatial operations for placekeys" do
      location = Location.create!(
        name: "San Francisco", 
        latitude: 37.7749, 
        longitude: -122.4194
      )
      
      # Test a few of the spatial methods
      expect(location.neighboring_placekeys).to eq(["@5vg-7gq-tvz", "@5vg-7gq-tvy"])
      expect(location.placekey_boundary).to eq([[37.7, -122.4], [37.7, -122.5]])
      
      # Test the calculation of distance between two locations
      other_location = Location.create!(
        name: "Oakland", 
        latitude: 37.8044, 
        longitude: -122.2711
      )
      
      expect(location.distance_to(other_location)).to eq(123.45)
    end
  end
  
  describe "BatchProcessor integration" do
    before do
      # Create test locations
      test_locations.each do |loc|
        Location.create!(loc)
      end
    end
    
    it "processes all locations in batch" do
      batch_processor = PlacekeyRails::BatchProcessor.new(Location.all)
      results = batch_processor.process
      
      expect(results.size).to eq(test_locations.size)
      expect(results.all? { |r| r[:success] }).to be true
      
      # Check that all locations have placekeys
      Location.all.each do |location|
        expect(location.placekey).to be_present
        expect(location.placekey).to eq("@#{location.latitude.to_i}-#{location.longitude.to_i}-xyz")
      end
    end
    
    it "handles errors gracefully" do
      # Make one location fail by providing invalid coordinates
      bad_location = Location.create!(name: "Invalid", latitude: nil, longitude: nil)
      
      batch_processor = PlacekeyRails::BatchProcessor.new(Location.all)
      results = batch_processor.process
      
      # Find the result for our bad location
      bad_result = results.find { |r| r[:id] == bad_location.id }
      
      # Verify it reports failure
      expect(bad_result[:success]).to be false
      expect(bad_result[:error]).to be_present
      
      # But other locations should still succeed
      good_results = results.reject { |r| r[:id] == bad_location.id }
      expect(good_results.all? { |r| r[:success] }).to be true
    end
  end
  
  # Form helper tests are now in spec/integration/form_helper_spec.rb
  
  describe "JavaScript components integration", js: true do
    # These tests require Capybara and JavaScript support
    # For now, we'll add a placeholder and rely on the individual component tests
    it "coordinates JS components work together" do
      pending "Requires full JS testing environment with Capybara"
      
      # In a real test, we would:
      # 1. Visit the new location page
      # 2. Fill in latitude/longitude and verify placekey auto-generation
      # 3. Test address lookup functionality
      # 4. Verify map display and interaction
    end
  end
  
  describe "Complete workflow integration" do
    it "supports the entire location management workflow" do
      # 1. Create a location with coordinates
      location = Location.create!(
        name: "Test Location",
        latitude: 37.7749,
        longitude: -122.4194
      )
      
      # 2. Verify placekey generation
      expect(location.placekey).to eq("@37--122-xyz")
      
      # 3. Update with address information
      location.update(
        street_address: "123 Main St",
        city: "San Francisco",
        region: "CA",
        postal_code: "94105"
      )
      
      # 4. Process in batch with other locations
      other_location = Location.create!(
        name: "Other Location",
        latitude: 34.0522,
        longitude: -118.2437
      )
      
      batch_processor = PlacekeyRails::BatchProcessor.new(Location.all)
      results = batch_processor.process
      
      # 5. Verify results
      expect(results.size).to eq(2)
      expect(results.all? { |r| r[:success] }).to be true
      
      # 6. Test spatial operations between locations
      distance = location.distance_to(other_location)
      expect(distance).to eq(123.45)
      
      # 7. Verify neighboring placekeys
      neighbors = location.neighboring_placekeys
      expect(neighbors).to eq(["@5vg-7gq-tvz", "@5vg-7gq-tvy"])
    end
  end
  
  # Edge case testing
  describe "Edge cases" do
    let(:api_client) { PlacekeyRails.default_client }
    
    it "handles invalid coordinates gracefully" do
      # Test with out-of-range values
      invalid_location = Location.new(
        name: "Invalid Coordinates",
        latitude: 95.0,  # Out of range
        longitude: -122.4194
      )
      
      expect(invalid_location).not_to be_valid
      expect(invalid_location.errors[:latitude]).to be_present
    end
    
    it "handles API error conditions" do
      # Mock API error
      allow(api_client).to receive(:lookup_placekey).and_raise(
        PlacekeyRails::ApiError.new(500, "API Error")
      )
      
      # Create location that would trigger API lookup
      location = Location.create!(
        name: "API Error Test",
        street_address: "123 Main St",
        city: "San Francisco",
        region: "CA",
        postal_code: "94105"
      )
      
      # Attempt to process with API error condition
      batch_processor = PlacekeyRails::BatchProcessor.new(Location.all)
      results = batch_processor.process
      
      # Verify error is captured
      expect(results.first[:success]).to be false
      expect(results.first[:error]).to include("API Error")
    end
    
    it "handles rate limiting scenarios" do
      # Mock rate limit error
      allow(api_client).to receive(:lookup_placekeys).and_raise(
        PlacekeyRails::RateLimitExceededError.new
      )
      
      # Create multiple locations
      5.times do |i|
        Location.create!(
          name: "Rate Limit Test #{i}",
          latitude: 37.7749 + (i * 0.01),
          longitude: -122.4194 - (i * 0.01)
        )
      end
      
      # Attempt batch processing
      batch_processor = PlacekeyRails::BatchProcessor.new(Location.all)
      
      # Should handle rate limit without crashing
      expect { batch_processor.process }.not_to raise_error
    end
  end
end
