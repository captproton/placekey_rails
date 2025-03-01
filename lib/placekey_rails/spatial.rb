require 'set'
require 'placekey_rails/constants'
require 'placekey_rails/h3_adapter'
require 'placekey_rails/converter'

module PlacekeyRails
  module Spatial
    extend self
    
    def get_neighboring_placekeys(placekey, dist=1)
      h3_integer = Converter.placekey_to_h3_int(placekey)
      neighboring_h3 = H3Adapter.gridDisk(h3_integer, dist)
      neighboring_h3.map { |h| Converter.h3_int_to_placekey(h) }.to_set
    end
    
    def placekey_distance(placekey_1, placekey_2)
      geo_1 = H3Adapter.cellToLatLng(Converter.placekey_to_h3_int(placekey_1))
      geo_2 = H3Adapter.cellToLatLng(Converter.placekey_to_h3_int(placekey_2))
      geo_distance(geo_1, geo_2)
    end
    
    def placekey_to_hex_boundary(placekey, geo_json=false)
      h3_integer = Converter.placekey_to_h3_int(placekey)
      boundary = H3Adapter.cellToBoundary(h3_integer)
      
      if geo_json
        boundary.map { |lat, lng| [lng, lat] }
      else
        boundary
      end
    end
    
    def placekey_to_polygon(placekey, geo_json=false)
      boundary = placekey_to_hex_boundary(placekey, geo_json)
      
      if geo_json
        RGeo::Cartesian.factory.polygon(
          RGeo::Cartesian.factory.linear_ring(
            boundary.map { |lng, lat| RGeo::Cartesian.factory.point(lng, lat) }
          )
        )
      else
        RGeo::Cartesian.factory.polygon(
          RGeo::Cartesian.factory.linear_ring(
            boundary.map { |lat, lng| RGeo::Cartesian.factory.point(lat, lng) }
          )
        )
      end
    end
    
    def placekey_to_wkt(placekey, geo_json=false)
      polygon = placekey_to_polygon(placekey, geo_json)
      polygon.as_text
    end
    
    def placekey_to_geojson(placekey)
      polygon = placekey_to_polygon(placekey, geo_json=true)
      RGeo::GeoJSON.encode(polygon)
    end
    
    def polygon_to_placekeys(poly, include_touching=false, geo_json=false)
      if geo_json
        # Transform (long, lat) to (lat, long)
        poly = transform_coordinates(poly) { |lng, lat| [lat, lng] }
      end
      
      buffer_size = 2e-3
      buffered_poly = poly.buffer(buffer_size)
      
      # Get candidate hexagons using H3 polyfill
      candidate_hexes = H3Adapter.polyfill(buffered_poly, 10)
      
      interior_hexes = []
      boundary_hexes = []
      
      candidate_hexes.each do |h|
        hex_boundary = H3Adapter.cellToBoundary(h)
        hex_poly = RGeo::Cartesian.factory.polygon(
          RGeo::Cartesian.factory.linear_ring(
            hex_boundary.map { |lat, lng| RGeo::Cartesian.factory.point(lat, lng) }
          )
        )
        
        if poly.contains?(hex_poly)
          interior_hexes << h
        elsif poly.intersects?(hex_poly)
          if include_touching || !poly.touches?(hex_poly)
            boundary_hexes << h
          end
        end
      end
      
      {
        interior: interior_hexes.map { |h| Converter.h3_int_to_placekey(h) },
        boundary: boundary_hexes.map { |h| Converter.h3_int_to_placekey(h) }
      }
    end
    
    def wkt_to_placekeys(wkt, include_touching=false, geo_json=false)
      poly = RGeo::WKT.parse(wkt)
      polygon_to_placekeys(poly, include_touching, geo_json)
    end
    
    def geojson_to_placekeys(geojson, include_touching=false, geo_json=true)
      if geojson.is_a?(String)
        poly = RGeo::GeoJSON.decode(geojson)
      else
        poly = RGeo::GeoJSON.decode(geojson.to_json)
      end
      
      polygon_to_placekeys(poly, include_touching, geo_json)
    end
    
    private
    
    def geo_distance(geo_1, geo_2)
      earth_radius = 6371 # In km
      
      lat_1 = degrees_to_radians(geo_1[0])
      long_1 = degrees_to_radians(geo_1[1])
      lat_2 = degrees_to_radians(geo_2[0])
      long_2 = degrees_to_radians(geo_2[1])
      
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