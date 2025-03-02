module PlacekeyRails
  module Concerns
    module Placekeyable
      extend ActiveSupport::Concern

      included do
        validates :placekey, format: { with: /\A(@[23456789bcdfghjkmnpqrstvwxyzeu]{3}-[23456789bcdfghjkmnpqrstvwxyzeu]{3}-[23456789bcdfghjkmnpqrstvwxyzeu]{3}|[23456789bcdfghjkmnpqrstvwxyz]+-[23456789bcdfghjkmnpqrstvwxyz]+@[23456789bcdfghjkmnpqrstvwxyzeu]{3}-[23456789bcdfghjkmnpqrstvwxyzeu]{3}-[23456789bcdfghjkmnpqrstvwxyzeu]{3})\z/,
                                    message: "is not a valid Placekey format" },
                  allow_blank: true, if: :placekey_validatable?

        before_validation :generate_placekey, if: :should_generate_placekey?

        scope :with_placekey, -> { where.not(placekey: [nil, '']) }
      end

      # Check if coordinates are available to generate placekey
      def coordinates_available?
        respond_to?(:latitude) && respond_to?(:longitude) &&
          latitude.present? && longitude.present?
      end

      # Generate a placekey from coordinates
      def generate_placekey
        return unless coordinates_available?
        self.placekey = PlacekeyRails.geo_to_placekey(latitude.to_f, longitude.to_f)
      end

      # Convert placekey to geo coordinates [lat, long]
      def placekey_to_geo
        return nil unless placekey.present?
        PlacekeyRails.placekey_to_geo(placekey)
      end

      # Get the H3 index for the placekey
      def placekey_to_h3
        return nil unless placekey.present?
        PlacekeyRails.placekey_to_h3(placekey)
      end

      # Get the boundary coordinates for the placekey hexagon
      def placekey_boundary(geo_json = false)
        return nil unless placekey.present?
        PlacekeyRails.placekey_to_hex_boundary(placekey, geo_json)
      end

      # Convert placekey to a GeoJSON representation
      def placekey_to_geojson
        return nil unless placekey.present?
        PlacekeyRails.placekey_to_geojson(placekey)
      end

      # Find neighboring placekeys
      def neighboring_placekeys(distance = 1)
        return [] unless placekey.present?
        PlacekeyRails.get_neighboring_placekeys(placekey, distance)
      end

      # Calculate distance to another placekey or placekeyable record
      def distance_to(other)
        return nil unless placekey.present?

        other_placekey = case other
                          when String
                            other
                          when respond_to?(:placekey)
                            other.placekey
                          else
                            return nil
                          end

        return nil unless other_placekey.present?
        PlacekeyRails.placekey_distance(placekey, other_placekey)
      end

      private

      def placekey_validatable?
        respond_to?(:placekey) && placekey.present?
      end

      def should_generate_placekey?
        respond_to?(:placekey) && placekey.blank? && coordinates_available?
      end

      module ClassMethods
        # Find records within a specified distance of a placekey
        def within_distance(origin_placekey, max_distance_meters)
          # First get all potential neighbors at a reasonable grid distance
          grid_distance = estimate_grid_distance(max_distance_meters)
          neighbor_keys = PlacekeyRails.get_neighboring_placekeys(origin_placekey, grid_distance).to_a
          
          # Find records with those placekeys
          candidates = with_placekey.where(placekey: neighbor_keys)
          
          # Further filter by exact distance
          candidates.select do |record|
            distance = PlacekeyRails.placekey_distance(origin_placekey, record.placekey)
            distance <= max_distance_meters
          end
        end

        # Find records within a specified distance of coordinates
        def near_coordinates(latitude, longitude, max_distance_meters)
          origin_placekey = PlacekeyRails.geo_to_placekey(latitude.to_f, longitude.to_f)
          within_distance(origin_placekey, max_distance_meters)
        end

        # Find records within a polygon defined by a GeoJSON object
        def within_geojson(geojson_data)
          result = PlacekeyRails.geojson_to_placekeys(geojson_data)
          all_placekeys = result[:interior] + result[:boundary]
          with_placekey.where(placekey: all_placekeys)
        end

        # Find records within a polygon defined by WKT
        def within_wkt(wkt_data)
          result = PlacekeyRails.wkt_to_placekeys(wkt_data)
          all_placekeys = result[:interior] + result[:boundary]
          with_placekey.where(placekey: all_placekeys)
        end

        # Batch geocode records that have addresses but no placekeys
        def batch_geocode_addresses(batch_size = 100, options = {})
          raise "Placekey API client not set up" unless PlacekeyRails.default_client
          
          # Determine which fields to use based on the model's columns
          address_field = options[:address_field] || :street_address
          city_field = options[:city_field] || :city
          region_field = options[:region_field] || :region
          postal_code_field = options[:postal_code_field] || :postal_code
          country_field = options[:country_field] || :iso_country_code
          
          # Find records that need geocoding
          scope = where(placekey: [nil, ''])
          
          # Ensure address field is present
          scope = scope.where.not(address_field => [nil, ''])
          
          processed_count = 0
          success_count = 0
          
          scope.find_in_batches(batch_size: batch_size) do |group|
            places = group.map do |record|
              query = {
                street_address: record[address_field],
                query_id: record.id.to_s
              }
              
              # Add optional fields if present
              query[:city] = record[city_field] if record.respond_to?(city_field) && record[city_field].present?
              query[:region] = record[region_field] if record.respond_to?(region_field) && record[region_field].present?
              query[:postal_code] = record[postal_code_field] if record.respond_to?(postal_code_field) && record[postal_code_field].present?
              query[:iso_country_code] = record[country_field] if record.respond_to?(country_field) && record[country_field].present?
              
              query
            end
            
            results = PlacekeyRails.lookup_placekeys(places)
            processed_count += places.size
            
            # Update records with placekeys
            results.each do |result|
              if result['placekey'].present? && result['query_id'].present?
                record = scope.find_by(id: result['query_id'])
                if record && record.update(placekey: result['placekey'])
                  success_count += 1
                end
              end
            end
            
            # Yield progress if a block is given
            yield(processed_count, success_count) if block_given?
          end
          
          { processed: processed_count, successful: success_count }
        end
        
        private
        
        # Estimate the appropriate grid distance based on meters
        def estimate_grid_distance(meters)
          # This is a simple heuristic based on the prefix distance dictionary
          distances = PlacekeyRails.get_prefix_distance_dict
          
          if meters > 20000
            3  # For very large distances, use a large grid distance
          elsif meters > 5000
            2  # For medium distances
          else
            1  # For small distances
          end
        end
      end
    end
  end
end
