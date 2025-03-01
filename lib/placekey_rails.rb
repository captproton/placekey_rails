require "placekey_rails/version"
require "placekey_rails/engine"
require "placekey_rails/constants"
require "h3"
require "rgeo"
require "httparty"

# Autoload the component modules
require "placekey_rails/h3_adapter"
require "placekey_rails/converter"
require "placekey_rails/validator"
require "placekey_rails/spatial"
require "placekey_rails/client"

module PlacekeyRails
  class Error < StandardError; end
  
  # Default API client used for convenience methods
  @default_client = nil
  
  class << self
    # Accessor for the default client
    attr_reader :default_client
    
    # Set up a default client for convenience methods
    # @param api_key [String] The Placekey API key
    # @param options [Hash] Additional options for the client
    def setup_client(api_key, options = {})
      @default_client = Client.new(api_key, options)
    end
    
    # Convenience methods at module level
    def geo_to_placekey(lat, long)
      Converter.geo_to_placekey(lat, long)
    end

    def placekey_to_geo(placekey)
      Converter.placekey_to_geo(placekey)
    end

    def placekey_to_h3(placekey)
      Converter.placekey_to_h3(placekey)
    end

    def h3_to_placekey(h3_string)
      Converter.h3_to_placekey(h3_string)
    end

    def placekey_format_is_valid(placekey)
      Validator.placekey_format_is_valid(placekey)
    end

    def get_neighboring_placekeys(placekey, dist=1)
      Spatial.get_neighboring_placekeys(placekey, dist)
    end

    def placekey_distance(placekey_1, placekey_2)
      Spatial.placekey_distance(placekey_1, placekey_2)
    end

    def get_prefix_distance_dict
      {
        0 => 2.004e7,
        1 => 2.004e7,
        2 => 2.777e6,
        3 => 1.065e6,
        4 => 1.524e5,
        5 => 2.177e4,
        6 => 8227.0,
        7 => 1176.0,
        8 => 444.3,
        9 => 63.47
      }
    end

    # Additional convenience methods for spatial operations
    def placekey_to_hex_boundary(placekey, geo_json=false)
      Spatial.placekey_to_hex_boundary(placekey, geo_json)
    end

    def placekey_to_polygon(placekey, geo_json=false)
      Spatial.placekey_to_polygon(placekey, geo_json)
    end

    def placekey_to_wkt(placekey, geo_json=false)
      Spatial.placekey_to_wkt(placekey, geo_json)
    end

    def placekey_to_geojson(placekey)
      Spatial.placekey_to_geojson(placekey)
    end

    def polygon_to_placekeys(poly, include_touching=false, geo_json=false)
      Spatial.polygon_to_placekeys(poly, include_touching, geo_json)
    end

    def wkt_to_placekeys(wkt, include_touching=false, geo_json=false)
      Spatial.wkt_to_placekeys(wkt, include_touching, geo_json)
    end

    def geojson_to_placekeys(geojson, include_touching=false, geo_json=true)
      Spatial.geojson_to_placekeys(geojson, include_touching, geo_json)
    end

    # API Client convenience methods
    def list_free_datasets
      Client.list_free_datasets
    end

    def return_free_datasets_location_by_name(name, url: false)
      Client.return_free_datasets_location_by_name(name, url: url)
    end

    def return_free_dataset_joins_by_name(names, url: false)
      Client.return_free_dataset_joins_by_name(names, url: url)
    end
    
    # Additional API client convenience methods that require an initialized client
    
    # Look up a placekey for a location
    # @param params [Hash] The location parameters
    # @param fields [Array] Optional fields to request
    # @return [Hash] The API response
    def lookup_placekey(params, fields = nil)
      ensure_client_setup
      default_client.lookup_placekey(params, fields)
    end
    
    # Look up placekeys for multiple locations
    # @param places [Array<Hash>] The locations
    # @param fields [Array] Optional fields to request
    # @param batch_size [Integer] Batch size for requests
    # @param verbose [Boolean] Whether to log detailed information
    # @return [Array<Hash>] The API responses
    def lookup_placekeys(places, fields = nil, batch_size = 100, verbose = false)
      ensure_client_setup
      default_client.lookup_placekeys(places, fields, batch_size, verbose)
    end
    
    # Process a dataframe with the Placekey API
    # @param dataframe [Rover::DataFrame] The DataFrame to process
    # @param column_mapping [Hash] Mapping from API fields to DataFrame columns
    # @param fields [Array] Optional fields to request
    # @param batch_size [Integer] Batch size for requests
    # @param verbose [Boolean] Whether to log detailed information
    # @return [Rover::DataFrame] The processed DataFrame
    def placekey_dataframe(dataframe, column_mapping, fields = nil, batch_size = 100, verbose = false)
      ensure_client_setup
      default_client.placekey_dataframe(dataframe, column_mapping, fields, batch_size, verbose)
    end
    
    private
    
    def ensure_client_setup
      unless default_client
        raise Error, "Default API client not set up. Call PlacekeyRails.setup_client(api_key) first."
      end
    end
  end
end
