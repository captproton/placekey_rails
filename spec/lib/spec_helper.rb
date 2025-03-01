# Mock the H3 module for testing
unless defined?(H3)
  puts "Setting up H3 mock module for tests"
  
  stub_const("H3", Module.new)
  
  # Create the necessary submodules
  module H3
    module Indexing; end
    module Inspection; end
    module Hierarchy; end
    module Regions; end
    
    # Define the H3::Indexing methods
    class << Indexing
      def geo_to_h3(coords, resolution)
        123456789
      end
      
      def h3_to_geo(index)
        [37.7371, -122.44283]
      end
      
      def string_to_h3(h3_string)
        123456789
      end
      
      def h3_to_string(index)
        "8a2830828767fff"
      end
      
      def h3_to_geo_boundary(index)
        [[37.776, -122.418], [37.776, -122.418], [37.776, -122.418], 
         [37.776, -122.418], [37.776, -122.418], [37.776, -122.418]]
      end
    end
    
    # Define the H3::Inspection methods
    class << Inspection
      def h3_is_valid(index)
        true
      end
    end
    
    # Define the H3::Hierarchy methods
    class << Hierarchy
      def hex_range(index, k)
        [123456789]
      end
      
      def hex_ring(index, k)
        [123456789]
      end
    end
    
    # Define the H3::Regions methods
    class << Regions
      def polyfill(coords, holes, resolution)
        [123456789]
      end
    end
  end
end