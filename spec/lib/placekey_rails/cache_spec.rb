require 'spec_helper'

RSpec.describe PlacekeyRails::Cache do
  subject(:cache) { described_class.new(3) } # Small max_size for easier testing

  describe "#initialize" do
    it "creates an empty cache with specified size" do
      expect(cache.size).to eq(0)
    end
  end

  describe "#get" do
    it "returns nil for non-existent keys" do
      expect(cache.get("non-existent")).to be_nil
    end

    it "returns the value for existing keys" do
      cache.set("key1", "value1")
      expect(cache.get("key1")).to eq("value1")
    end

    it "updates access order when getting a value" do
      cache.set("key1", "value1")
      cache.set("key2", "value2")
      cache.set("key3", "value3")

      # Access key1 to make it most recently used
      cache.get("key1")

      # Add a new key to evict the least recently used
      cache.set("key4", "value4")

      # key2 should be evicted as it's now the least recently used
      expect(cache.key?("key1")).to be true
      expect(cache.key?("key2")).to be false
      expect(cache.key?("key3")).to be true
      expect(cache.key?("key4")).to be true
    end
  end

  describe "#set" do
    it "adds a new key-value pair" do
      cache.set("key1", "value1")
      expect(cache.get("key1")).to eq("value1")
    end

    it "updates existing keys" do
      cache.set("key1", "value1")
      cache.set("key1", "updated-value")
      expect(cache.get("key1")).to eq("updated-value")
    end

    it "evicts least recently used item when at capacity" do
      cache.set("key1", "value1")
      cache.set("key2", "value2")
      cache.set("key3", "value3")

      # Adding a 4th item should evict the oldest (key1)
      cache.set("key4", "value4")

      expect(cache.key?("key1")).to be false
      expect(cache.key?("key2")).to be true
      expect(cache.key?("key3")).to be true
      expect(cache.key?("key4")).to be true
    end
  end

  describe "#clear" do
    it "removes all items from the cache" do
      cache.set("key1", "value1")
      cache.set("key2", "value2")

      cache.clear

      expect(cache.size).to eq(0)
      expect(cache.key?("key1")).to be false
      expect(cache.key?("key2")).to be false
    end
  end

  describe "#size" do
    it "returns the number of items in the cache" do
      expect(cache.size).to eq(0)

      cache.set("key1", "value1")
      expect(cache.size).to eq(1)

      cache.set("key2", "value2")
      expect(cache.size).to eq(2)

      cache.set("key1", "updated-value")
      expect(cache.size).to eq(2)
    end
  end

  describe "#keys" do
    it "returns all keys in the cache" do
      cache.set("key1", "value1")
      cache.set("key2", "value2")

      expect(cache.keys).to contain_exactly("key1", "key2")
    end
  end

  describe "#key?" do
    it "checks if a key exists without affecting access order" do
      cache.set("key1", "value1")
      cache.set("key2", "value2")
      cache.set("key3", "value3")

      # Check if key1 exists but don't update its access order
      expect(cache.key?("key1")).to be true

      # Add a new key to evict the least recently used
      cache.set("key4", "value4")

      # key1 should be evicted as it remained the least recently used
      expect(cache.key?("key1")).to be false
    end
  end
end
