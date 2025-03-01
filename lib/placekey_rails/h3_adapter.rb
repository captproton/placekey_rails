require 'h3'

module PlacekeyRails
  # This adapter module provides a bridge between the H3 gem's method naming
  # and the method names used in the Placekey specification.
  # This is needed because the H3 gem uses Ruby conventions (snake_case),
  # while the Placekey Python library uses camelCase.
  module H3Adapter
    extend self

    # Core indexing functions
    def lat_lng_to_cell(lat, lng, resolution)
      H3.from_geo_coordinates([lat, lng], resolution)
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

    def polyfill(coordinates, holes, resolution)
      # H3 gem's polyfill doesn't use holes parameter
      H3.polyfill(coordinates, resolution)
    end
  end
end
