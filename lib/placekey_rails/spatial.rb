require 'set'
require 'placekey_rails/constants'
require 'placekey_rails/h3_adapter'
require 'placekey_rails/converter'

module PlacekeyRails
  module Spatial
    extend self

    def get_neighboring_placekeys(placekey, dist = 1)
      h3_integer = Converter.placekey_to_h3_int(placekey)
      neighboring_h3 = H3Adapter.grid_disk(h3_integer, dist)
      Set.new(neighboring_h3.map { |h3| Converter.h3_int_to_placekey(h3) })
    end

    def placekey_distance(placekey_1, placekey_2)
      geo_1 = H3Adapter.cell_to_lat_lng(Converter.placekey_to_h3_int(placekey_1))
      geo_2 = H3Adapter.cell_to_lat_lng(Converter.placekey_to_h3_int(placekey_2))
      geo_distance(geo_1, geo_2)
    end

    def placekey_to_hex_boundary(placekey, geo_json: false)
      h3_integer = Converter.placekey_to_h3_int(placekey)
      boundary = H3Adapter.cell_to_boundary(h3_integer)

      if geo_json
        boundary.map { |coord| [coord[1], coord[0]] }
      else
        boundary
      end
    end

    def placekey_to_polygon(placekey)
      boundary = placekey_to_hex_boundary(placekey)
      factory = RGeo::Cartesian.factory
      points = boundary.map { |coord| factory.point(coord[1], coord[0]) }
      factory.polygon(factory.linear_ring(points))
    end

    def placekey_to_wkt(placekey, geo_json=false)
      polygon = placekey_to_polygon(placekey)
      polygon.as_text
    end

    def placekey_to_geojson(placekey)
      polygon = placekey_to_polygon(placekey)
      RGeo::GeoJSON.encode(polygon)
    end

    def polygon_to_placekeys(polygon, resolution = 10)
      buffered_poly = polygon.buffer(0)
      candidate_hexes = H3Adapter.polyfill(buffered_poly.coordinates, [], resolution)

      interior = []
      boundary = []

      candidate_hexes.each do |hex|
        placekey = Converter.h3_int_to_placekey(hex)
        if polygon.contains?(placekey_to_polygon(placekey))
          interior << placekey
        elsif polygon.intersects?(placekey_to_polygon(placekey))
          boundary << placekey
        end
      end

      { interior: interior.uniq, boundary: boundary.uniq }
    end

    def wkt_to_placekeys(wkt_string)
      factory = RGeo::Cartesian.factory
      polygon = factory.parse_wkt(wkt_string)
      polygon_to_placekeys(polygon)
    end

    def geojson_to_placekeys(geojson)
      poly = if geojson.is_a?(String)
        RGeo::GeoJSON.decode(geojson)
      else
        RGeo::GeoJSON.decode(geojson.to_json)
      end
      polygon_to_placekeys(poly)
    end

    private

    def geo_distance(coord1, coord2)
      earth_radius = 6371 # In km

      lat_1 = degrees_to_radians(coord1[0])
      long_1 = degrees_to_radians(coord1[1])
      lat_2 = degrees_to_radians(coord2[0])
      long_2 = degrees_to_radians(coord2[1])

      hav_lat = 0.5 * (1 - Math.cos(lat_1 - lat_2))
      hav_long = 0.5 * (1 - Math.cos(long_1 - long_2))
      radical = Math.sqrt(hav_lat + Math.cos(lat_1) * Math.cos(lat_2) * hav_long)

      2 * earth_radius * Math.asin(radical) * 1000 # Convert to meters
    end

    def degrees_to_radians(degrees)
      degrees * Math::PI / 180
    end

    def transform_coordinates(geometry)
      case geometry
      when RGeo::Feature::Point
        yield(geometry.x, geometry.y)
      when RGeo::Feature::LineString
        RGeo::Cartesian.factory.line_string(
          geometry.points.map { |p| yield(p.x, p.y) }
        )
      when RGeo::Feature::Polygon
        RGeo::Cartesian.factory.polygon(
          transform_coordinates(geometry.exterior_ring),
          geometry.interior_rings.map { |r| transform_coordinates(r) }
        )
      else
        geometry
      end
    end
  end
end
