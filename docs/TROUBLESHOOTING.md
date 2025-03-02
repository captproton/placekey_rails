# PlacekeyRails Troubleshooting Guide

This document provides solutions for common issues you might encounter when using the PlacekeyRails gem.

## Table of Contents

- [Installation Issues](#installation-issues)
- [H3 Library Issues](#h3-library-issues)
- [API Client Issues](#api-client-issues)
- [Conversion Issues](#conversion-issues)
- [Rails Integration Issues](#rails-integration-issues)
- [Performance Optimization](#performance-optimization)

## Installation Issues

### Missing System Dependencies

**Problem:** Installation fails with errors about missing H3 libraries or CMake.

**Solution:**

Ensure you have the required system dependencies installed:

On macOS:
```bash
brew install cmake
brew install h3
```

On Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install cmake
# H3 requires manual installation from source
git clone https://github.com/uber/h3.git
cd h3
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON .
make
sudo make install
```

On CentOS/RHEL:
```bash
sudo yum install cmake
# H3 requires manual installation from source
git clone https://github.com/uber/h3.git
cd h3
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON .
make
sudo make install
```

### Ruby Version Compatibility

**Problem:** Errors related to Ruby version compatibility.

**Solution:**

PlacekeyRails requires Ruby 3.2.0 or later. Upgrade your Ruby version using your preferred version manager:

```bash
# Using RVM
rvm install 3.2.0
rvm use 3.2.0

# Using rbenv
rbenv install 3.2.0
rbenv local 3.2.0
```

### Bundler Issues

**Problem:** Bundler complains about platform compatibility.

**Solution:**

Add the necessary platforms to your Gemfile.lock:

```bash
bundle lock --add-platform x86_64-linux
bundle lock --add-platform arm64-darwin
```

## H3 Library Issues

### H3 Binding Errors

**Problem:** Errors like "cannot load such file -- h3" or issues calling H3 functions.

**Solution:**

1. Check that the H3 library is properly installed:
   ```bash
   # On macOS
   brew list h3
   
   # On Linux
   ldconfig -p | grep libh3
   ```

2. If installed but still getting errors, try reinstalling the H3 gem:
   ```bash
   gem uninstall h3
   bundle install
   ```

3. If using JRuby or another alternative Ruby implementation, note that H3 requires MRI Ruby.

### Memory Leaks with H3

**Problem:** The application memory usage grows over time when making many H3 operations.

**Solution:**

1. Ensure you're using the latest version of the H3 gem
2. Add explicit GC calls after processing large batches:
   ```ruby
   # After processing a large batch
   GC.start
   ```

3. Consider reusing H3 objects instead of creating new ones for each operation

## API Client Issues

### Rate Limiting Errors

**Problem:** Getting 429 errors or rate limit exceeded messages.

**Solution:**

1. Use the built-in retry mechanism with higher max_retries:
   ```ruby
   client = PlacekeyRails::Client.new(api_key, max_retries: 30)
   ```

2. Add exponential backoff by customizing the client:
   ```ruby
   client = PlacekeyRails::Client.new(api_key, max_retries: 20)
   ```

3. Split large batches into smaller ones:
   ```ruby
   results = []
   places.each_slice(10) do |batch|
     results.concat(client.lookup_placekeys(batch, batch_size: 10))
     sleep 1 # Add a small delay between batches
   end
   ```

### Authentication Errors

**Problem:** Getting 401 unauthorized errors.

**Solution:**

1. Verify your API key is correct:
   ```ruby
   # Test with a simple lookup
   begin
     PlacekeyRails.setup_client("your-api-key")
     result = PlacekeyRails.lookup_placekey({latitude: 37.7371, longitude: -122.44283})
     puts "Success: #{result['placekey']}"
   rescue => e
     puts "Error: #{e.message}"
   end
   ```

2. Check if your account has the necessary permissions for the API

3. If using environment variables, ensure they're properly loaded:
   ```ruby
   PlacekeyRails.setup_client(ENV.fetch('PLACEKEY_API_KEY'))
   ```

### Missing or Invalid Fields

**Problem:** Getting errors about missing or invalid parameters.

**Solution:**

1. Review the required parameters for API calls:
   - For coordinates: both `latitude` and `longitude` are required
   - For addresses: at least `street_address` and either `region` and `postal_code` or `region` and `city`

2. Validate your parameters before making API calls:
   ```ruby
   def valid_params?(params)
     return true if params[:latitude].present? && params[:longitude].present?
     return true if params[:street_address].present? && params[:region].present? && 
                   (params[:postal_code].present? || params[:city].present?)
     false
   end
   
   places.select! { |place| valid_params?(place) }
   ```

## Conversion Issues

### Invalid Placekey Format

**Problem:** Getting errors about invalid Placekey format.

**Solution:**

1. Validate Placekeys before using them:
   ```ruby
   if PlacekeyRails.placekey_format_is_valid(placekey)
     # Proceed with the operation
   else
     # Handle the invalid Placekey
   end
   ```

2. Check for common formatting issues:
   - Missing "@" symbol
   - Incorrect tuple lengths
   - Invalid characters
   - Incorrect separators

### Incorrect Coordinate Conversions

**Problem:** Getting unexpected coordinates from Placekey conversions.

**Solution:**

1. Remember that Placekeys represent hexagons with a specific resolution, not exact points
2. The H3 resolution used is 10, which has a hexagon edge length of about 66 meters
3. Converting coordinates to a Placekey and back will return the center of the hexagon, not the original coordinates

```ruby
# Original coordinates
original_lat, original_lng = 37.7371, -122.44283

# Convert to Placekey and back
placekey = PlacekeyRails.geo_to_placekey(original_lat, original_lng)
new_lat, new_lng = PlacekeyRails.placekey_to_geo(placekey)

# Calculate the difference
require 'geocoder'
distance = Geocoder::Calculations.distance_between(
  [original_lat, original_lng],
  [new_lat, new_lng],
  units: :km
) * 1000 # Convert to meters

puts "Distance: #{distance} meters"
```

## Rails Integration Issues

### ActiveRecord Integration

**Problem:** Issues with integrating Placekeys into ActiveRecord models.

**Solution:**

1. Ensure you've added the Placekey column to your model:
   ```ruby
   # In a migration
   add_column :locations, :placekey, :string
   add_index :locations, :placekey
   ```

2. Add validations and callbacks:
   ```ruby
   class Location < ApplicationRecord
     validates :placekey, uniqueness: true, allow_nil: true
     
     before_validation :generate_placekey, if: -> { latitude.present? && longitude.present? && placekey.blank? }
     
     private
     
     def generate_placekey
       self.placekey = PlacekeyRails.geo_to_placekey(latitude, longitude)
     end
   end
   ```

3. Use transactions for batch processing:
   ```ruby
   Location.transaction do
     # Process locations in batches
     Location.where(placekey: nil).find_each(batch_size: 100) do |location|
       if location.latitude.present? && location.longitude.present?
         location.update(placekey: PlacekeyRails.geo_to_placekey(location.latitude, location.longitude))
       end
     end
   end
   ```

### API Client in Background Jobs

**Problem:** Issues with using the API client in background jobs.

**Solution:**

1. Set up the client explicitly in each job:
   ```ruby
   class GeocodeJob < ApplicationJob
     queue_as :default
     
     def perform(location_id)
       location = Location.find(location_id)
       client = PlacekeyRails::Client.new(ENV['PLACEKEY_API_KEY'])
       
       result = client.lookup_placekey({
         street_address: location.street_address,
         city: location.city,
         region: location.region,
         postal_code: location.postal_code
       })
       
       if result['placekey'].present?
         location.update(placekey: result['placekey'])
       end
     end
   end
   ```

2. Use connection pooling for the API client:
   ```ruby
   # config/initializers/placekey.rb
   require 'connection_pool'
   
   PLACEKEY_CLIENT_POOL = ConnectionPool.new(size: 5, timeout: 5) do
     PlacekeyRails::Client.new(ENV['PLACEKEY_API_KEY'])
   end
   
   # In your job
   class GeocodeJob < ApplicationJob
     queue_as :default
     
     def perform(location_id)
       location = Location.find(location_id)
       
       PLACEKEY_CLIENT_POOL.with do |client|
         result = client.lookup_placekey({
           street_address: location.street_address,
           city: location.city,
           region: location.region,
           postal_code: location.postal_code
         })
         
         if result['placekey'].present?
           location.update(placekey: result['placekey'])
         end
       end
     end
   end
   ```

## Performance Optimization

### Batch Processing

**Problem:** Processing large numbers of locations is slow.

**Solution:**

1. Use batch API calls when possible:
   ```ruby
   # Instead of calling for each place
   places = locations.map { |location| location_to_params(location) }
   results = PlacekeyRails.lookup_placekeys(places, batch_size: 100)
   ```

2. Process in parallel when appropriate:
   ```ruby
   require 'parallel'
   
   # Split into batches
   batches = places.each_slice(100).to_a
   
   # Process batches in parallel (adjust the number based on your API rate limits)
   results = Parallel.map(batches, in_processes: 2) do |batch|
     PlacekeyRails.lookup_placekeys(batch)
   end
   
   # Flatten results
   all_results = results.flatten
   ```

### Caching

**Problem:** Repeated lookups for the same locations waste API calls and time.

**Solution:**

1. Use Rails caching:
   ```ruby
   # app/services/placekey_service.rb
   class PlacekeyService
     def self.lookup_placekey(params)
       cache_key = "placekey/#{Digest::MD5.hexdigest(params.to_json)}"
       
       Rails.cache.fetch(cache_key, expires_in: 30.days) do
         PlacekeyRails.lookup_placekey(params)
       end
     end
   end
   ```

2. Create a database table for cached lookups:
   ```ruby
   # In a migration
   create_table :placekey_lookups do |t|
     t.string :street_address
     t.string :city
     t.string :region
     t.string :postal_code
     t.decimal :latitude, precision: 10, scale: 7
     t.decimal :longitude, precision: 10, scale: 7
     t.string :placekey
     t.jsonb :api_response
     t.timestamps
   end
   
   add_index :placekey_lookups, [:street_address, :city, :region, :postal_code], 
             name: 'index_placekey_lookups_on_address'
   add_index :placekey_lookups, [:latitude, :longitude]
   add_index :placekey_lookups, :placekey
   ```

   ```ruby
   # app/models/placekey_lookup.rb
   class PlacekeyLookup < ApplicationRecord
     validates :placekey, presence: true
     
     def self.find_or_create_by_coordinates(lat, lng)
       existing = where(latitude: lat, longitude: lng).first
       return existing if existing
       
       result = PlacekeyRails.lookup_placekey({latitude: lat, longitude: lng})
       
       if result['placekey'].present?
         create(
           latitude: lat,
           longitude: lng,
           placekey: result['placekey'],
           api_response: result
         )
       end
     end
     
     def self.find_or_create_by_address(address_params)
       street = address_params[:street_address]
       city = address_params[:city]
       region = address_params[:region]
       postal_code = address_params[:postal_code]
       
       existing = where(
         street_address: street,
         city: city,
         region: region,
         postal_code: postal_code
       ).first
       return existing if existing
       
       result = PlacekeyRails.lookup_placekey(address_params)
       
       if result['placekey'].present?
         create(
           street_address: street,
           city: city,
           region: region,
           postal_code: postal_code,
           placekey: result['placekey'],
           api_response: result
         )
       end
     end
   end
   ```

### Memory Optimization

**Problem:** Processing large datasets leads to high memory usage.

**Solution:**

1. Use streaming processing:
   ```ruby
   # Instead of loading everything into memory
   CSV.open("output.csv", "wb") do |csv|
     csv << ["address", "city", "state", "zip", "placekey"]
     
     CSV.foreach("input.csv", headers: true) do |row|
       result = PlacekeyRails.lookup_placekey({
         street_address: row["address"],
         city: row["city"],
         region: row["state"],
         postal_code: row["zip"]
       })
       
       csv << [row["address"], row["city"], row["state"], row["zip"], result["placekey"]]
     end
   end
   ```

2. Process in chunks:
   ```ruby
   def process_large_file(file_path, chunk_size = 1000)
     total_rows = `wc -l #{file_path}`.to_i - 1 # Subtract header
     chunks = (total_rows / chunk_size.to_f).ceil
     
     chunks.times do |chunk_index|
       start_line = chunk_index * chunk_size + 2 # +2 for 1-indexing and header
       end_line = [(chunk_index + 1) * chunk_size + 1, total_rows + 1].min
       
       # Extract chunk to temp file
       chunk_file = "#{file_path}.chunk.#{chunk_index}"
       `sed -n '1p;#{start_line},#{end_line}p' #{file_path} > #{chunk_file}`
       
       # Process chunk
       process_chunk(chunk_file)
       
       # Clean up
       File.delete(chunk_file)
     end
   end
   
   def process_chunk(chunk_file)
     places = []
     CSV.foreach(chunk_file, headers: true) do |row|
       places << {
         street_address: row["address"],
         city: row["city"],
         region: row["state"],
         postal_code: row["zip"],
         query_id: row["id"]
       }
     end
     
     results = PlacekeyRails.lookup_placekeys(places)
     
     # Save results
     CSV.open("#{chunk_file}.results", "wb") do |csv|
       csv << ["id", "placekey"]
       results.each do |result|
         csv << [result["query_id"], result["placekey"]]
       end
     end
   end
   ```

3. Use database-backed queues for large jobs:
   ```ruby
   # app/jobs/process_location_batch_job.rb
   class ProcessLocationBatchJob < ApplicationJob
     queue_as :placekey
     
     def perform(location_ids)
       locations = Location.where(id: location_ids)
       places = locations.map do |location|
         {
           street_address: location.street_address,
           city: location.city,
           region: location.region,
           postal_code: location.postal_code,
           query_id: location.id.to_s
         }
       end
       
       results = PlacekeyRails.lookup_placekeys(places)
       
       results.each do |result|
         if result["placekey"].present?
           location_id = result["query_id"].to_i
           Location.find(location_id).update(placekey: result["placekey"])
         end
       end
     end
   end
   
   # app/services/bulk_placekey_service.rb
   class BulkPlacekeyService
     def self.process_all_locations(batch_size = 100)
       # Queue up batches
       Location.where(placekey: nil).pluck(:id).each_slice(batch_size) do |location_ids|
         ProcessLocationBatchJob.perform_later(location_ids)
       end
     end
   end
   ```
