module PlacekeyRails
  # Simple in-memory cache with LRU (Least Recently Used) eviction strategy
  class Cache
    def initialize(max_size = 1000)
      @max_size = max_size
      @cache = {}
      @access_order = []
      @mutex = Mutex.new
    end
    
    def get(key)
      @mutex.synchronize do
        if @cache.key?(key)
          # Move this key to the end of the access order (most recently used)
          @access_order.delete(key)
          @access_order.push(key)
          return @cache[key]
        end
        nil
      end
    end
    
    def set(key, value)
      @mutex.synchronize do
        # If key already exists, update access order
        if @cache.key?(key)
          @access_order.delete(key)
        # If we're at capacity, remove least recently used item
        elsif @cache.size >= @max_size
          lru_key = @access_order.shift
          @cache.delete(lru_key)
        end
        
        # Add the new key-value pair
        @cache[key] = value
        @access_order.push(key)
        value
      end
    end
    
    def clear
      @mutex.synchronize do
        @cache.clear
        @access_order.clear
      end
    end
    
    def size
      @cache.size
    end
    
    def keys
      @cache.keys
    end
    
    # Check if a key exists in cache without affecting access order
    def key?(key)
      @cache.key?(key)
    end
  end
end
