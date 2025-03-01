require "h3"

module PlacekeyRails
  # This adapter module provides a bridge between the actual H3 gem methods
  # and the methods expected by our Placekey implementation.
  module H3Adapter
    extend self

    # Core methods using the actual H3 gem method names
    def lat_lng_to_cell(lat, lng, resolution)
      H3.from_geo_coordinates([ lat, lng ], resolution)
    end

    def cell_to_lat_lng(h3_index)
      H3.to_geo_coordinates(h3_index)
    end

    def string_to_h3(h3_string)
      H3.from_string(h3_string)
    end

    def h3_to_string(h3_index)
      H3.to_string(h3_index)
    end

    def is_valid_cell(h3_index)
      H3.valid?(h3_index)
    end

    def grid_disk(h3_index, k)
      H3.k_ring(h3_index, k)
    end

    def cell_to_boundary(h3_index)
      H3.to_boundary(h3_index)
    end

    # The polyfill method - we ignore the holes parameter since H3 gem doesn't support it
    def polyfill(coordinates, holes = nil, resolution)
      # Use the H3 gem's polyfill method with coordinates and resolution
      # Ignore the holes parameter since it's not supported by the H3 gem
      H3.polyfill(coordinates, resolution)
    end

    # CamelCase aliases for compatibility with tests and some code
    alias latLngToCell lat_lng_to_cell
    alias cellToLatLng cell_to_lat_lng
    alias stringToH3 string_to_h3
    alias h3ToString h3_to_string
    alias isValidCell is_valid_cell
    alias gridDisk grid_disk
    alias cellToBoundary cell_to_boundary
  end
end
