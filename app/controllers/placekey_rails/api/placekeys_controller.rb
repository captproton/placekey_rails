module PlacekeyRails
  module Api
    class PlacekeysController < ::PlacekeyRails::ApplicationController
      protect_from_forgery with: :exception

      # GET /placekey_rails/api/placekeys/:placekey
      def show
        placekey = params[:id]

        unless PlacekeyRails.placekey_format_is_valid(placekey)
          render json: { error: "Invalid Placekey format" }, status: :unprocessable_entity
          return
        end

        begin
          lat, lng = PlacekeyRails.placekey_to_geo(placekey)
          boundary = PlacekeyRails.placekey_to_hex_boundary(placekey, true)

          render json: {
            placekey: placekey,
            center: { lat: lat, lng: lng },
            boundary: boundary,
            geojson: PlacekeyRails.placekey_to_geojson(placekey)
          }
        rescue => e
          render json: { error: "Error processing Placekey: #{e.message}" }, status: :unprocessable_entity
        end
      end

      # POST /placekey_rails/api/placekeys/from_coordinates
      def from_coordinates
        lat = params[:latitude].to_f
        lng = params[:longitude].to_f

        unless valid_coordinates?(lat, lng)
          render json: { error: "Invalid coordinates" }, status: :unprocessable_entity
          return
        end

        begin
          placekey = PlacekeyRails.geo_to_placekey(lat, lng)

          render json: {
            placekey: placekey,
            latitude: lat,
            longitude: lng
          }
        rescue => e
          render json: { error: "Error generating Placekey: #{e.message}" }, status: :unprocessable_entity
        end
      end

      # POST /placekey_rails/api/placekeys/from_address
      def from_address
        unless PlacekeyRails.default_client
          render json: { error: "Placekey API client not configured" }, status: :service_unavailable
          return
        end

        begin
          result = PlacekeyRails.lookup_placekey(address_params)

          if result && result["placekey"].present?
            render json: {
              placekey: result["placekey"],
              query_id: result["query_id"],
              source: "api"
            }
          else
            render json: { error: "No Placekey found for this address" }, status: :not_found
          end
        rescue => e
          render json: { error: "Error looking up Placekey: #{e.message}" }, status: :unprocessable_entity
        end
      end

      private

      def valid_coordinates?(lat, lng)
        lat.is_a?(Numeric) && lng.is_a?(Numeric) &&
          lat >= -90 && lat <= 90 &&
          lng >= -180 && lng <= 180
      end

      def address_params
        params.permit(
          :street_address,
          :city,
          :region,
          :postal_code,
          :iso_country_code,
          :query_id
        )
      end
    end
  end
end
