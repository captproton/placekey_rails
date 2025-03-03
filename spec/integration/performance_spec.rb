require 'rails_helper'

RSpec.describe "Performance Testing", type: :integration do
  # These tests focus on performance with larger datasets
  
  let(:api_client) { instance_double(PlacekeyRails::Client) }
  
  before do
    # Configure PlacekeyRails to use our mock API client
    allow(PlacekeyRails).to receive(:default_client).and_return(api_client)
    
    # Mock API client methods
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
    
    # Standard module mocks
    allow(PlacekeyRails).to receive(:geo_to_placekey) do |lat, lng|
      "@#{lat.to_i}-#{lng.to_i}-xyz"
    end
    
    allow(PlacekeyRails).to receive(:placekey_to_geo) do |placekey|
      parts = placekey.gsub('@', '').split('-')
      [parts[0].to_f, -parts[1].to_f]
    end
    
    allow(PlacekeyRails).to receive(:get_neighboring_placekeys) do |placekey, dist|
      5.times.map { |i| "@#{i}-#{i}-xyz" }
    end
    
    # Clean up test data
    Location.destroy_all
  end
  
  describe "Batch processing performance" do
    it "processes large batches efficiently" do
      # Generate a larger set of locations
      locations = []
      50.times do |i|
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
      
      # Measure records per second
      records_per_second = locations.size / processing_time
      
      # Log the performance metrics
      puts "Processed #{locations.size} records in #{processing_time.round(2)} seconds"
      puts "Performance: #{records_per_second.round(2)} records/second"
      
      # This is a flexible test - actual performance will vary by environment
      # In a real test we'd have specific benchmarks
      expect(processing_time).to be < 30.0  # Very generous limit for the test
    end
    
    it "scales linearly with batch size" do
      # Test with different batch sizes to ensure linear scaling
      batch_sizes = [10, 25, 50]
      times = {}
      
      batch_sizes.each do |size|
        # Create locations for this batch size
        Location.destroy_all
        locations = []
        size.times do |i|
          locations << Location.create!(
            name: "Scaling Test #{i}",
            latitude: 37.7749 + (i * 0.01),
            longitude: -122.4194 - (i * 0.01)
          )
        end
        
        # Process and time it
        batch_processor = PlacekeyRails::BatchProcessor.new(locations)
        
        start_time = Time.now
        batch_processor.process
        end_time = Time.now
        
        times[size] = end_time - start_time
      end
      
      # Log scaling results
      times.each do |size, time|
        puts "Size #{size}: #{time.round(2)} seconds, #{(size / time).round(2)} records/second"
      end
      
      # Check if processing scales roughly linearly
      # Calculate records per second for each batch size
      rps = times.transform_values { |time| time > 0 ? batch_sizes.first / time : 0 }
      
      # The records per second should be relatively consistent across batch sizes
      # This is a very permissive test that just checks for major non-linearities
      variance = rps.values.max / rps.values.min if rps.values.min > 0
      
      # Log the variance
      puts "Performance variance across batch sizes: #{variance&.round(2) || 'N/A'}"
      
      # In a real-world test, we'd expect more specific performance bounds
      # For this test, we'll just check that variance isn't excessive
      expect(variance).to be < 5.0 if variance  # Should be within 5x (very generous)
    end
  end
  
  describe "Spatial query performance" do
    before do
      # Create a grid of locations for spatial queries
      @grid_locations = []
      7.times do |x|
        7.times do |y|
          @grid_locations << Location.create!(
            name: "Grid #{x},#{y}",
            latitude: 37.75 + (x * 0.01),
            longitude: -122.45 + (y * 0.01)
          )
        end
      end
      
      # Center location for distance calculations
      @center = Location.create!(
        name: "Center",
        latitude: 37.78,
        longitude: -122.42
      )
    end
    
    it "efficiently finds locations within a distance" do
      # Skip if not using a real database
      skip "Test requires actual database" unless defined?(ActiveRecord::Base)
      
      # Get the locations near the center
      start_time = Time.now
      
      # Use the within_distance scope from Placekeyable
      nearby = Location.within_distance(@center.placekey, 5000)
      
      end_time = Time.now
      query_time = end_time - start_time
      
      # Log performance
      puts "Found #{nearby.count} locations within 5km in #{query_time.round(4)} seconds"
      
      # This test is mostly for benchmarking - verify basic functionality
      expect(nearby).to include(@center)
      expect(query_time).to be < 1.0  # Very generous for the test
    end
    
    it "efficiently finds locations near coordinates" do
      # Skip if not using a real database
      skip "Test requires actual database" unless defined?(ActiveRecord::Base)
      
      # Get locations near specific coordinates
      start_time = Time.now
      
      # Use the near_coordinates scope from Placekeyable
      nearby = Location.near_coordinates(37.78, -122.42, 5000)
      
      end_time = Time.now
      query_time = end_time - start_time
      
      # Log performance
      puts "Found #{nearby.count} locations near coordinates in #{query_time.round(4)} seconds"
      
      # Verify basic functionality
      expect(nearby).to include(@center)
      expect(query_time).to be < 1.0  # Very generous for the test
    end
    
    it "performs efficient distance calculations between many locations" do
      # Calculate distances between the center and all grid locations
      start_time = Time.now
      
      distances = @grid_locations.map do |location|
        @center.distance_to(location)
      end
      
      end_time = Time.now
      calc_time = end_time - start_time
      
      # Log performance
      puts "Calculated #{distances.size} distances in #{calc_time.round(4)} seconds"
      puts "Average: #{(calc_time / distances.size).round(6)} seconds per calculation"
      
      # Verify reasonable performance
      expect(distances.size).to eq(@grid_locations.size)
      expect(calc_time).to be < 1.0  # Very generous for the test
    end
    
    it "efficiently retrieves neighboring placekeys for many locations" do
      start_time = Time.now
      
      # Get neighbors for all grid locations
      neighbor_sets = @grid_locations.map do |location|
        location.neighboring_placekeys
      end
      
      end_time = Time.now
      calc_time = end_time - start_time
      
      # Count total neighbors retrieved
      total_neighbors = neighbor_sets.sum(&:size)
      
      # Log performance
      puts "Retrieved #{total_neighbors} neighbors for #{@grid_locations.size} locations in #{calc_time.round(4)} seconds"
      puts "Average: #{(calc_time / @grid_locations.size).round(6)} seconds per location"
      
      # Verify reasonable performance
      expect(calc_time).to be < 2.0  # Very generous for the test
    end
  end
  
  describe "Memory usage" do
    it "handles large result sets without excessive memory consumption" do
      # This is difficult to test precisely in a spec
      # We'll focus on successfully processing larger datasets
      
      # Create a larger dataset
      many_locations = []
      100.times do |i|
        many_locations << Location.create!(
          name: "Memory Test #{i}",
          latitude: 37.7749 + (i * 0.01),
          longitude: -122.4194 - (i * 0.01)
        )
      end
      
      # Measure memory before
      memory_before = GetProcessMem.new.mb rescue nil
      
      # Process in batches
      batch_processor = PlacekeyRails::BatchProcessor.new(many_locations, batch_size: 20)
      results = batch_processor.process
      
      # Measure memory after
      memory_after = GetProcessMem.new.mb rescue nil
      
      if memory_before && memory_after
        memory_increase = memory_after - memory_before
        puts "Memory before: #{memory_before.round(2)}MB, after: #{memory_after.round(2)}MB"
        puts "Increase: #{memory_increase.round(2)}MB"
        
        # In a real test, we'd have specific memory targets
        # Here we just verify the test ran without errors
        expect(memory_increase).to be < 100  # Very generous - 100MB increase max
      end
      
      # Verify all records were processed
      expect(results.size).to eq(many_locations.size)
      expect(results.all? { |r| r[:success] }).to be true
    end
  end
  
  describe "Concurrent operations" do
    it "handles multiple batch processes without interference" do
      # Skip in environments that don't support threads
      skip "Test requires thread support" unless defined?(Thread)
      
      # Create datasets
      datasets = 3.times.map do |set|
        10.times.map do |i|
          Location.create!(
            name: "Concurrent Set #{set} - #{i}",
            latitude: 37.7 + (set * 0.1) + (i * 0.01),
            longitude: -122.4 - (set * 0.1) - (i * 0.01)
          )
        end
      end
      
      # Process concurrently
      start_time = Time.now
      
      threads = datasets.map do |dataset|
        Thread.new do
          batch_processor = PlacekeyRails::BatchProcessor.new(dataset)
          batch_processor.process
        end
      end
      
      # Wait for all threads to complete
      results = threads.map(&:value)
      
      end_time = Time.now
      total_time = end_time - start_time
      
      # Log performance
      total_records = datasets.sum(&:size)
      puts "Processed #{total_records} records in #{total_time.round(2)} seconds using #{datasets.size} concurrent batches"
      
      # Verify all succeeded
      expect(results.flatten.size).to eq(total_records)
      expect(results.flatten.all? { |r| r[:success] }).to be true
    end
  end
end
