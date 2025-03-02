require 'spec_helper'

RSpec.describe PlacekeyRails do
  describe "caching functionality" do
    after do
      # Clean up after each test
      PlacekeyRails.instance_variable_set(:@cache, nil)
    end

    describe ".enable_caching" do
      it "creates a new cache instance" do
        expect(PlacekeyRails.cache).to be_nil
        PlacekeyRails.enable_caching
        expect(PlacekeyRails.cache).to be_a(PlacekeyRails::Cache)
      end

      it "accepts a max_size parameter" do
        PlacekeyRails.enable_caching(max_size: 500)
        expect(PlacekeyRails.cache).to be_a(PlacekeyRails::Cache)
        # We can't directly test the max_size as it's private, but we can test it indirectly
        # by adding more than the default and making sure old ones are evicted
      end
    end

    describe ".cache" do
      it "returns nil when caching is not enabled" do
        expect(PlacekeyRails.cache).to be_nil
      end

      it "returns the cache instance when caching is enabled" do
        PlacekeyRails.enable_caching
        expect(PlacekeyRails.cache).to be_a(PlacekeyRails::Cache)
      end
    end

    describe ".clear_cache" do
      it "clears the cache when enabled" do
        PlacekeyRails.enable_caching
        cache = PlacekeyRails.cache
        
        # Mock the clear method on the cache instance
        expect(cache).to receive(:clear).once
        
        PlacekeyRails.clear_cache
      end

      it "does nothing when cache is not enabled" do
        expect { PlacekeyRails.clear_cache }.not_to raise_error
      end
    end
  end
end
