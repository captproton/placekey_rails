require 'h3'

module PlacekeyRails
  # This adapter module provides a bridge between the H3 gem's method naming
  # and the method names used in the Placekey specification.
  # This is needed because the H3 gem uses Ruby conventions (snake_case),
  # while the Placekey Python library uses camelCase.
  module H3Adapter
    extend self

    # Adapts H3::Indexing.geo_to_h3 to latLngToCell
    def latLngToCell(lat, lng, resolution)
      H3::Indexing.geo_to_h3([lat, lng], resolution)
    end

    # Adapts H3::Indexing.h3_to_geo to cellToLatLng
    def cellToLatLng(h3_index)
      H3::Indexing.h3_to_geo(h3_index)
    end

    # Adapts H3::Indexing.string_to_h3 to stringToH3
    def stringToH3(h3_string)
      H3::Indexing.string_to_h3(h3_string)
    end

    # Adapts H3::Indexing.h3_to_string to h3ToString
    def h3ToString(h3_integer)
      H3::Indexing.h3_to_string(h3_integer)
    end

    # Adapts H3::Inspection.h3_is_valid to isValidCell
    def isValidCell(h3_index)
      H3::Inspection.h3_is_valid(h3_index)
    end

    # Adapts H3::Hierarchy.hex_ring to gridRing
    def gridRing(h3_index, k)
      H3::Hierarchy.hex_ring(h3_index, k)
    end

    # Adapts H3::Hierarchy.hex_range to gridDisk
    def gridDisk(h3_index, k)
      H3::Hierarchy.hex_range(h3_index, k)
    end

    # Adapts H3::Indexing.h3_to_geo_boundary to cellToBoundary
    def cellToBoundary(h3_index)
      H3::Indexing.h3_to_geo_boundary(h3_index)
    end

    # Adapts H3::Regions.polyfill to polyfill
    def polyfill(polygon, resolution)
      # Converting the polygon to the format expected by H3::Regions.polyfill
      # H3::Regions.polyfill expects a set of coordinates as argument
      
      # This is a simplified version - might need adjustment based on actual polygon format
      # and specific requirements of H3::Regions.polyfill
      if polygon.respond_to?(:exterior_ring) && polygon.exterior_ring.respond_to?(:points)
        # Extract exterior ring coordinates as [lat, lng] pairs
        coords = polygon.exterior_ring.points.map { |p| [p.y, p.x] }
        
        # Get any holes (interior rings)
        holes = []
        if polygon.respond_to?(:interior_rings) && !polygon.interior_rings.empty?
          holes = polygon.interior_rings.map do |ring|
            ring.points.map { |p| [p.y, p.x] }
          end
        end
        
        # Call the actual polyfill method
        H3::Regions.polyfill(coords, holes, resolution)
      else
        # Fallback for simpler polygon representation or different format
        # This might need customization based on actual usage patterns
        H3::Regions.polyfill(polygon, [], resolution)
      end
    end
  end
end