# Performance Optimization Guide

This guide covers techniques for optimizing performance when using the PlacekeyRails gem in your application.

## Caching

PlacekeyRails provides built-in caching to reduce API calls and improve performance. This is especially important when working with the Placekey API, as it has rate limits.

### Enabling Caching

To enable caching:

```ruby
# In an initializer or before using the API
PlacekeyRails.enable_caching(max_size: 1000)
```

The `max_size` parameter determines how many items to keep in the cache. The default is 1000, which should be sufficient for most applications.

### Cache Configuration

The cache uses an LRU (Least Recently Used) eviction policy, which means it will automatically remove the least recently accessed items when it reaches capacity.

### Clearing the Cache

To clear the cache manually:

```ruby
PlacekeyRails.clear_cache
```

### Disabling Caching for Specific Requests

If you need to bypass the cache for specific requests, you can use the API client directly:

```ruby
client = PlacekeyRails.default_client
client.lookup_placekey(params, use_cache: false)
```

## Batch Processing

For processing large collections of records, use the BatchProcessor to efficiently handle operations in batches:

### Batch Geocoding

```ruby
# Process up to 100 records at a time
result = PlacekeyRails.batch_geocode(Location.where(placekey: nil), batch_size: 100)

# With progress reporting
PlacekeyRails.batch_geocode(Location.where(placekey: nil)) do |processed, successful|
  puts "Processed #{processed} locations (#{successful} successful)"
end
```

### Custom Batch Operations

For more control over batch processing:

```ruby
processor = PlacekeyRails.batch_processor(batch_size: 50)

# Process with a custom operation
processor.process(Location.all, ->(record) {
  # Do something with the record
  record.update(processed: true)
})
```

## Database Optimization

### Indexing

Add an index on the `placekey` column for faster lookups:

```ruby
# In a migration
add_index :locations, :placekey
```

### Spatial Queries

When performing spatial queries, use the appropriate method:

```ruby
# Find records near a placekey
nearby = Location.within_distance('@5vg-7gq-tvz', 1000) # 1000 meters

# Find records near coordinates
nearby = Location.near_coordinates(37.7371, -122.44283, 1000)
```

The `within_distance` method automatically uses an optimized algorithm that first retrieves placekeys at an appropriate grid distance and then filters by exact distance.

## Memory Usage

### Working with Large Datasets

When working with large datasets:

1. Process records in batches using `find_in_batches` or the built-in batch methods
2. Avoid loading all records into memory at once
3. Use the `placekey_dataframe` method for processing large CSV files without loading everything into memory

Example:

```ruby
# Process 10000 records in batches of 100
Location.where(placekey: nil).find_in_batches(batch_size: 100) do |batch|
  PlacekeyRails.batch_geocode(batch)
end
```

### Limiting API Response Size

When making API requests, limit the fields returned to only what you need:

```ruby
PlacekeyRails.lookup_placekey(params, fields: ['placekey'])
```

## Background Processing

For very large datasets or slow operations, consider using background processing:

```ruby
# Using Sidekiq or similar
class GeocodeLocationsJob
  include Sidekiq::Job
  
  def perform(batch_size = 100)
    batch_processor = PlacekeyRails.batch_processor(batch_size: batch_size)
    batch_processor.geocode(Location.where(placekey: nil))
  end
end
```

## Monitoring Performance

The `PlacekeyRails::Client` logs API usage information. To see detailed logs:

```ruby
PlacekeyRails.setup_client(ENV['PLACEKEY_API_KEY'], logger: Rails.logger)

# For verbose logging in specific operations
PlacekeyRails.lookup_placekeys(places, verbose: true)
```

## API Rate Limits

The Placekey API has the following rate limits:

- Single requests: 1000 requests per minute
- Batch requests: 10 requests per minute

The client automatically respects these limits and will throttle requests accordingly.

## Connection Pooling

For applications with high concurrency, consider using a connection pool:

```ruby
# Example using the connection_pool gem
require 'connection_pool'

PLACEKEY_CLIENT_POOL = ConnectionPool.new(size: 5, timeout: 5) do
  PlacekeyRails::Client.new(ENV['PLACEKEY_API_KEY'])
end

# Then use it in your code
PLACEKEY_CLIENT_POOL.with do |client|
  client.lookup_placekey(params)
end
```

## Benchmarking

You can use the Ruby benchmark module to measure performance:

```ruby
require 'benchmark'

time = Benchmark.measure do
  PlacekeyRails.batch_geocode(Location.all)
end

puts "Elapsed time: #{time.real} seconds"
```

## Profiling

For more detailed performance analysis, use a profiler like ruby-prof:

```ruby
require 'ruby-prof'

RubyProf.start
# Code to profile
PlacekeyRails.batch_geocode(Location.all)
result = RubyProf.stop

# Print a flat profile to text
printer = RubyProf::FlatPrinter.new(result)
printer.print(STDOUT)
```

## Optimization Strategies

### Precomputing Placekeys

If your application frequently performs spatial queries, precompute Placekeys for all locations:

```ruby
# In a migration or one-time task
Location.where(placekey: nil).find_each do |location|
  location.generate_placekey
  location.save
end
```

### Denormalization

For frequently accessed data, consider denormalizing Placekey information:

```ruby
# Example migration
class AddPlacekeyInfoToLocations < ActiveRecord::Migration[6.1]
  def change
    add_column :locations, :placekey, :string
    add_column :locations, :h3_index, :string
    add_column :locations, :geocoded_at, :datetime
    
    add_index :locations, :placekey
    add_index :locations, :h3_index
  end
end
```

### Use of Redis for Distributed Caching

For applications running on multiple servers, consider using Redis for distributed caching:

```ruby
# Implement a Redis-backed cache adapter
class RedisCache
  def initialize(redis_connection, namespace = 'placekey:cache')
    @redis = redis_connection
    @namespace = namespace
  end
  
  def get(key)
    json = @redis.get("#{@namespace}:#{key}")
    JSON.parse(json) if json
  end
  
  def set(key, value)
    @redis.set("#{@namespace}:#{key}", value.to_json)
    value
  end
  
  def clear
    @redis.keys("#{@namespace}:*").each do |key|
      @redis.del(key)
    end
  end
end

# Then use it with PlacekeyRails
redis_cache = RedisCache.new(Redis.new)
PlacekeyRails.instance_variable_set(:@cache, redis_cache)
```

## Integration with GIS Systems

If you're using PostGIS or another spatial database:

1. Store both Placekeys and geographic data
2. Use the database's spatial capabilities for complex queries
3. Use Placekeys for external communication and API integration

Example with ActiveRecord and PostGIS:

```ruby
class CreateSpatialLocations < ActiveRecord::Migration[6.1]
  def change
    create_table :locations do |t|
      t.string :name
      t.string :placekey
      t.st_point :coordinates, geographic: true
      t.timestamps
    end
    
    add_index :locations, :placekey
    add_index :locations, :coordinates, using: :gist
  end
end

class Location < ApplicationRecord
  include PlacekeyRails::Concerns::Placekeyable
  
  # Custom method to use PostGIS for distance calculation
  def self.near_postgis(lat, lng, distance_meters)
    point = "POINT(#{lng} #{lat})"
    where("ST_DWithin(coordinates, ST_GeographyFromText('#{point}'), #{distance_meters})")
  end
  
  # Sync methods to keep Placekey and PostGIS coordinates in sync
  before_save :sync_coordinates
  
  def sync_coordinates
    if placekey_changed? && placekey.present?
      lat, lng = PlacekeyRails.placekey_to_geo(placekey)
      self.coordinates = "POINT(#{lng} #{lat})"
    elsif coordinates_changed? && coordinates.present?
      self.placekey = PlacekeyRails.geo_to_placekey(coordinates.lat, coordinates.lon)
    end
  end
end
```

## Performance Testing Considerations

When testing performance:

1. Use realistic data volumes
2. Test under concurrent load
3. Monitor memory usage
4. Test with caching enabled and disabled
5. Measure API call counts

Example performance test using Rails::Performance::Benchmarking:

```ruby
require 'test_helper'
require 'rails/performance_test_help'

class PlacekeyPerformanceTest < ActionDispatch::PerformanceTest
  def setup
    # Create test data
    1000.times do |i|
      Location.create(
        name: "Location #{i}",
        latitude: 37.7371 + (i * 0.001),
        longitude: -122.44283 + (i * 0.001)
      )
    end
  end
  
  def test_batch_geocoding
    benchmark "Batch geocoding 1000 locations" do
      PlacekeyRails.batch_geocode(Location.all)
    end
  end
  
  def test_spatial_query
    benchmark "Finding locations within 1000m" do
      Location.near_coordinates(37.7371, -122.44283, 1000)
    end
  end
end
```

## FAQ

**Q: My application is slow when processing a large number of records. What should I do?**

A: Process records in smaller batches and consider using background jobs. Also, make sure caching is enabled.

**Q: I'm hitting rate limits with the Placekey API. How can I avoid this?**

A: The client automatically handles rate limiting, but you might need to adjust your batch size or add exponential backoff for retries.

**Q: Should I store both Placekeys and coordinates in my database?**

A: Yes, storing both allows for more flexible querying and can reduce API calls.

**Q: How can I monitor the performance of Placekey operations?**

A: Use the verbose logging option and consider adding custom metrics to track API calls, cache hits/misses, and processing times.
