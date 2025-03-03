require 'rails_helper'

RSpec.describe "PlacekeyRails Edge Cases", type: :integration do
  let(:api_client) { instance_double(PlacekeyRails::Client) }
  
  before do
    # Configure PlacekeyRails to use our mock API client
    allow(PlacekeyRails).to receive(:default_client).and_return(api_client)
    
    # Default API client mock behavior
    allow(api_client).to receive(:lookup_placekey) do |params|
      lat = params[:latitude]
      lng = params[:longitude]
      
      {
        "placekey" => "@#{lat.to_i}-#{lng.to_i}-xyz",
        "query_id" => "test_#{lat}_#{lng}"
      }
    end
    
    allow(api_client).to receive(:lookup_placekeys) do |places|
      places.map do |place|
        lat = place[:latitude]
        lng = place[:longitude]
        
        {
          "placekey" => "@#{lat.to_i}-#{lng.to_i}-xyz",
          "query_id" => place[:query_id] || "test_#{lat}_#{lng}"
        }
      end
    end
    
    # Standard PlacekeyRails module mocks
    allow(PlacekeyRails).to receive(:geo_to_placekey) do |lat, lng|
      "@#{lat.to_i}-#{lng.to_i}-xyz"
    end
    
    allow(PlacekeyRails).to receive(:placekey_to_geo) do |placekey|
      parts = placekey.gsub('@', '').split('-')
      [parts[0].to_f, -parts[1].to_f]
    end
    
    allow(PlacekeyRails).to receive(:placekey_format_is_valid).and_return(true)
    allow(PlacekeyRails).to receive(:placekey_to_h3).and_return("8a2830828767fff")
    allow(PlacekeyRails).to receive(:get_neighboring_placekeys).and_return(["@5vg-7gq-tvz", "@5vg-7gq-tvy"])
    allow(PlacekeyRails).to receive(:placekey_distance).and_return(123.45)
    
    # Clean up test data
    Location.destroy_all
  end
  
  describe "Invalid input handling" do
    it "rejects invalid latitude values" do
      location = Location.new(
        name: "Invalid Latitude",
        latitude: 100.0,  # Out of range
        longitude: -122.4194
      )
      
      expect(location).not_to be_valid
      expect(location.errors[:latitude]).to be_present
    end
    
    it "rejects invalid longitude values" do
      location = Location.new(
        name: "Invalid Longitude",
        latitude: 37.7749,
        longitude: -200.0  # Out of range
      )
      
      expect(location).not_to be_valid
      expect(location.errors[:longitude]).to be_present
    end
    
    it "handles nil coordinates gracefully" do
      location = Location.create!(name: "No Coordinates")
      
      # Should not have a placekey
      expect(location.placekey).to be_nil
      
      # Spatial methods should return appropriate nil values
      expect(location.placekey_to_geo).to be_nil
      expect(location.placekey_to_h3).to be_nil
      expect(location.placekey_boundary).to be_nil
      
      # Collections should be empty
      expect(location.neighboring_placekeys).to eq([])
    end
    
    it "validates placekey format when provided directly" do
      # Mock the validator to reject a specific format
      allow(PlacekeyRails).to receive(:placekey_format_is_valid) do |placekey|
        placekey != "invalid-format"
      end
      
      # This should fail validation
      location = Location.new(
        name: "Invalid Placekey",
        placekey: "invalid-format"
      )
      
      # Add custom validation to check placekey format
      location.instance_eval do
        def validate_placekey_format
          return unless placekey.present?
          errors.add(:placekey, "has invalid format") unless PlacekeyRails.placekey_format_is_valid(placekey)
        end
        validate :validate_placekey_format
      end
      
      expect(location).not_to be_valid
      expect(location.errors[:placekey]).to be_present
    end
  end
  
  describe "API error handling" do
    it "handles API connection errors" do
      # Mock connection failure
      allow(api_client).to receive(:lookup_placekey).and_raise(
        PlacekeyRails::ApiError.new(0, "Connection refused")
      )
      
      # Create a batch processor
      location = Location.create!(
        name: "API Error Test",
        latitude: 37.7749,
        longitude: -122.4194
      )
      
      batch_processor = PlacekeyRails::BatchProcessor.new([location])
      
      # Process should handle error without crashing
      results = batch_processor.process
      expect(results.first[:success]).to be false
      expect(results.first[:error]).to include("Connection refused")
    end
    
    it "handles API authentication errors" do
      # Mock authentication failure
      allow(api_client).to receive(:lookup_placekey).and_raise(
        PlacekeyRails::ApiError.new(401, "Unauthorized")
      )
      
      location = Location.create!(
        name: "Auth Error Test",
        latitude: 37.7749,
        longitude: -122.4194
      )
      
      batch_processor = PlacekeyRails::BatchProcessor.new([location])
      results = batch_processor.process
      
      expect(results.first[:success]).to be false
      expect(results.first[:error]).to include("Unauthorized")
    end
    
    it "handles rate limit errors" do
      # First call succeeds, second call fails with rate limit
      call_count = 0
      allow(api_client).to receive(:lookup_placekeys) do |places|
        call_count += 1
        if call_count == 1
          [{ "placekey" => "@5vg-7gq-tvz", "query_id" => "1" }]
        else
          raise PlacekeyRails::RateLimitExceededError.new
        end
      end
      
      # Create multiple locations
      locations = []
      3.times do |i|
        locations << Location.create!(
          name: "Rate Limit Test #{i}",
          latitude: 37.7749 + (i * 0.01),
          longitude: -122.4194 - (i * 0.01)
        )
      end
      
      # The batch processor should handle the rate limit and return partial results
      batch_processor = PlacekeyRails::BatchProcessor.new(locations, batch_size: 1)
      results = batch_processor.process
      
      # Should have some successes and some failures
      expect(results.count { |r| r[:success] }).to be > 0
      expect(results.count { |r| !r[:success] }).to be > 0
    end
    
    it "handles malformed API responses" do
      # Mock malformed response
      allow(api_client).to receive(:lookup_placekey).and_return(
        { "error" => "Invalid response", "status" => "error" }
      )
      
      location = Location.create!(
        name: "Bad Response Test",
        latitude: 37.7749,
        longitude: -122.4194
      )
      
      batch_processor = PlacekeyRails::BatchProcessor.new([location])
      results = batch_processor.process
      
      expect(results.first[:success]).to be false
    end
  end
  
  describe "Large dataset performance" do
    it "processes large batches efficiently" do
      # Create a larger set of locations
      locations = []
      20.times do |i|
        locations << Location.create!(
          name: "Performance Test #{i}",
          latitude: 37.7749 + (i * 0.01),
          longitude: -122.4194 - (i * 0.01)
        )
      end
      
      # Time the batch processing
      batch_processor = PlacekeyRails::BatchProcessor.new(locations)
      
      start_time = Time.now
      results = batch_processor.process
      end_time = Time.now
      
      processing_time = end_time - start_time
      
      # All should succeed
      expect(results.all? { |r| r[:success] }).to be true
      
      # Processing time should be reasonable
      # This is a placeholder - in a real test we'd have specific benchmarks
      expect(processing_time).to be < 10.0  # Very generous limit for the test
    end
    
    it "handles batch size configuration properly" do
      # Create test locations
      locations = []
      10.times do |i|
        locations << Location.create!(
          name: "Batch Size Test #{i}",
          latitude: 37.7749 + (i * 0.01),
          longitude: -122.4194 - (i * 0.01)
        )
      end
      
      # Mock the API client to track batch sizes
      batches = []
      allow(api_client).to receive(:lookup_placekeys) do |places|
        batches << places.size
        places.map do |place|
          { 
            "placekey" => "@5vg-7gq-tvz", 
            "query_id" => place[:query_id] || "test"
          }
        end
      end
      
      # Process with specific batch size
      batch_processor = PlacekeyRails::BatchProcessor.new(locations, batch_size: 3)
      batch_processor.process
      
      # Verify batch sizes
      expect(batches.size).to be >= 3  # Should have at least 3 batches
      expect(batches.all? { |size| size <= 3 }).to be true  # No batch should exceed 3
    end
  end
  
  describe "Component resilience" do
    it "fails gracefully when geocoding service is unavailable" do
      allow(api_client).to receive(:lookup_placekey).and_raise(
        StandardError.new("Geocoding service unavailable")
      )
      
      # Try to create a location that would trigger geocoding
      location = Location.new(
        name: "Geocoding Test",
        street_address: "123 Main St",
        city: "San Francisco",
        region: "CA" 
      )
      
      # It should still save, just without a placekey
      expect(location.save).to be true
      expect(location.placekey).to be_nil
    end
    
    it "recovers from temporary failures" do
      # Mock an API that fails the first two times, then succeeds
      call_count = 0
      allow(api_client).to receive(:lookup_placekey) do |params|
        call_count += 1
        if call_count <= 2
          raise PlacekeyRails::ApiError.new(500, "Temporary error")
        else
          { "placekey" => "@5vg-7gq-tvz", "query_id" => "test" }
        end
      end
      
      # Create a resilient batch processor with retries
      location = Location.create!(
        name: "Retry Test",
        latitude: 37.7749,
        longitude: -122.4194
      )
      
      # Configure a batch processor with retries
      batch_processor = PlacekeyRails::BatchProcessor.new(
        [location], 
        max_retries: 3
      )
      
      results = batch_processor.process
      
      # Should eventually succeed after retries
      expect(results.first[:success]).to be true
      expect(call_count).to be >= 3  # Should have tried at least 3 times
    end
  end
end
