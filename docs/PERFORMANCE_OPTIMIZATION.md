# Performance Optimization Plan for PlacekeyRails

## Overview

This document outlines the performance optimization strategies for the PlacekeyRails gem, focusing on reducing computation time, minimizing memory usage, and improving API interaction efficiency.

## Caching Strategies

### 1. API Response Caching

Implement caching for Placekey API responses to reduce redundant API calls:

```ruby
# lib/placekey_rails/client.rb

module PlacekeyRails
  class Client
    # Add caching capability
    def self.enable_caching(options = {})
      @cache_store = ActiveSupport::Cache::MemoryStore.new(size: options[:max_size] || 1000)
      @cache_enabled = true
    end
    
    def self.disable_caching
      @cache_enabled = false
    end
    
    def lookup_placekey(params = {}, fields = nil)
      cache_key = "placekey_lookup_#{params.to_s.hash}_#{fields.to_s.hash}"
      
      if self.class.cache_enabled? && (cached = self.class.cache_store.read(cache_key))
        return cached
      end
      
      result = make_api_call(params, fields)
      
      if self.class.cache_enabled? && result && result["placekey"]
        self.class.cache_store.write(cache_key, result)
      end
      
      result
    end
    
    private
    
    def self.cache_enabled?
      @cache_enabled == true
    end
    
    def self.cache_store
      @cache_store || ActiveSupport::Cache::NullStore.new
    end
  end
end
```

### 2. H3 Conversion Caching

Cache H3 conversion results to reduce redundant computation:

```ruby
module PlacekeyRails
  module Converter
    class << self
      def with_cache
        @cache ||= {}
        @cache_enabled = true
        yield
      ensure
        @cache_enabled = false
      end
      
      def geo_to_placekey(lat, long)
        cache_key = "geo_to_placekey_#{lat}_#{long}"
        
        if @cache_enabled && @cache[cache_key]
          return @cache[cache_key]
        end
        
        result = calculate_geo_to_placekey(lat, long)
        
        if @cache_enabled
          @cache[cache_key] = result
        end
        
        result
      end
      
      private
      
      def calculate_geo_to_placekey(lat, long)
        # Original implementation
      end
    end
  end
end
```

### 3. Database Query Optimization

Optimize database queries for spatial operations:

```ruby
module PlacekeyRails
  module Concerns
    module Placekeyable
      module ClassMethods
        def within_distance(placekey, distance_meters, options = {})
          # Use select to limit columns when possible
          select_columns = options[:select] || self.column_names
          
          # Use includes for eager loading
          includes_associations = options[:includes] || []
          
          # Use pluck for better performance when possible
          if options[:pluck_ids]
            pluck(:id)
          else
            where(placekey: PlacekeyRails.get_neighboring_placekeys(placekey))
              .select(select_columns)
              .includes(includes_associations)
          end
        end
      end
    end
  end
end
```

## JavaScript Optimization

### 1. Lazy Loading Maps

Optimize map loading to only initialize when visible:

```javascript
// app/javascript/controllers/placekey_map_controller.js
import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

export default class extends Controller {
  static targets = ["container"]
  
  connect() {
    // Only initialize map when visible
    if ('IntersectionObserver' in window) {
      const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            this.initializeMap()
            observer.unobserve(this.containerTarget)
          }
        })
      })
      
      observer.observe(this.containerTarget)
    } else {
      // Fallback for browsers without IntersectionObserver
      this.initializeMap()
    }
  }
  
  initializeMap() {
    // Map initialization code
  }
}
```

### 2. Debouncing API Calls

Implement debouncing for API calls triggered by user input:

```javascript
// app/javascript/controllers/placekey_lookup_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["address", "city", "lookupButton"]
  
  connect() {
    this.debounceTimer = null
    this.debouncedEnableButton = this.debounce(this.enableLookupButton, 300)
    
    this.addressTarget.addEventListener("input", () => {
      this.debouncedEnableButton()
    })
    
    this.cityTarget.addEventListener("input", () => {
      this.debouncedEnableButton()
    })
  }
  
  debounce(func, wait) {
    return () => {
      clearTimeout(this.debounceTimer)
      this.debounceTimer = setTimeout(() => {
        func.apply(this)
      }, wait)
    }
  }
  
  enableLookupButton() {
    // Check form validity and enable button if form is valid
  }
}
```

## Memory Usage Optimization

### 1. Batch Processing

Optimize batch processing to manage memory usage:

```ruby
module PlacekeyRails
  def self.batch_process(collection, batch_size: 100, &block)
    total = collection.count
    processed = 0
    
    collection.find_in_batches(batch_size: batch_size) do |batch|
      batch.each do |item|
        yield(item) if block_given?
        processed += 1
      end
      
      # Force garbage collection between batches for large datasets
      GC.start if total > 1000
    end
    
    processed
  end
end
```

### 2. Streaming Results

For large result sets, implement streaming:

```ruby
module PlacekeyRails
  module Spatial
    def self.geojson_to_placekeys_stream(geojson, &block)
      # Process the GeoJSON in chunks
      buffer = []
      buffer_size = 100
      
      polygon_to_placekeys_process(geojson) do |placekey|
        buffer << placekey
        
        if buffer.size >= buffer_size
          yield buffer if block_given?
          buffer = []
        end
      end
      
      yield buffer if buffer.any? && block_given?
    end
  end
end
```

## Performance Testing

### 1. Benchmarking Key Operations

Add benchmarking to identify bottlenecks:

```ruby
require 'benchmark'

module PlacekeyRails
  def self.benchmark(name, options = {})
    iterations = options[:iterations] || 100
    warming = options[:warming] || 10
    
    # Warming up
    warming.times { yield }
    
    # Actual benchmark
    time = Benchmark.measure do
      iterations.times { yield }
    end
    
    average_ms = (time.real * 1000) / iterations
    puts "#{name}: #{average_ms.round(2)} ms per operation (#{iterations} iterations)"
    
    average_ms
  end
end
```

### 2. Memory Profiling

Set up memory profiling for large operations:

```ruby
require 'memory_profiler'

module PlacekeyRails
  def self.profile_memory(name, &block)
    report = MemoryProfiler.report(&block)
    
    puts "Memory profiling for #{name}:"
    puts "Total allocated: #{report.total_allocated_memsize / 1024.0} KB"
    puts "Total retained: #{report.total_retained_memsize / 1024.0} KB"
    
    report
  end
end
```

## Implementation Plan

1. Add caching mechanisms to the API client first, as this will provide the most immediate performance benefits
2. Implement JavaScript optimizations for map components
3. Add batch processing optimizations for large datasets
4. Implement memory usage optimizations
5. Add performance testing utilities
6. Document all optimizations and provide usage guidelines

## Benchmarking Goals

- API client: Reduce API call latency by 50% for cached responses
- Map display: Reduce initial load time by 30%
- Batch processing: Handle 10,000+ records efficiently without memory issues
- Spatial operations: Optimize complex polygon operations to complete in under 5 seconds for typical use cases
