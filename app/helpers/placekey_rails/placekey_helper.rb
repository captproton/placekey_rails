module PlacekeyRails
  module PlacekeyHelper
    # Generate a formatted placekey string for display
    # Optionally highlighting the what/where parts differently
    def format_placekey(placekey, options = {})
      return "" unless placekey.present?

      what, where = PlacekeyRails::Converter.parse_placekey(placekey)

      if what.present?
        what_class = options[:what_class] || "placekey-what"
        where_class = options[:where_class] || "placekey-where"

        content_tag(:span, class: "placekey") do
          concat content_tag(:span, what, class: what_class)
          concat content_tag(:span, "@", class: "placekey-separator")
          concat content_tag(:span, where, class: where_class)
        end
      else
        content_tag(:span, placekey, class: options[:class] || "placekey")
      end
    end

    # Generate map data for a placekey that can be used with mapping libraries
    def placekey_map_data(placekey)
      return {} unless placekey.present? && PlacekeyRails.placekey_format_is_valid(placekey)

      lat, lng = PlacekeyRails.placekey_to_geo(placekey)
      boundary = PlacekeyRails.placekey_to_hex_boundary(placekey, true) # GeoJSON format

      {
        placekey: placekey,
        center: { lat: lat, lng: lng },
        boundary: boundary,
        geojson: PlacekeyRails.placekey_to_geojson(placekey)
      }
    end

    # Generate map data for a collection of placekeys
    def placekeys_map_data(placekeys)
      return [] unless placekeys.present?

      placekeys.map do |pk|
        placekey_map_data(pk)
      end
    end

    # Generate Leaflet.js map initialization code for a placekey
    def leaflet_map_for_placekey(placekey, options = {})
      return nil unless placekey.present? && PlacekeyRails.placekey_format_is_valid(placekey)

      map_data = placekey_map_data(placekey)
      container_id = options[:container_id] || "placekey-map"
      height = options[:height] || "400px"
      width = options[:width] || "100%"
      zoom = options[:zoom] || 15

      content_tag(:div, "", id: container_id, style: "height: #{height}; width: #{width};",
                data: {
                  controller: "placekey-map",
                  placekey_map_data_value: map_data.to_json,
                  placekey_map_zoom_value: zoom
                })
    end

    # Generate a card display for a placekey with optional info
    def placekey_card(placekey, options = {})
      return nil unless placekey.present? && PlacekeyRails.placekey_format_is_valid(placekey)

      title = options[:title] || "Placekey Information"
      show_map = options[:show_map].nil? ? true : options[:show_map]
      show_coords = options[:show_coords].nil? ? true : options[:show_coords]

      content_tag(:div, class: "placekey-card") do
        concat content_tag(:h3, title, class: "placekey-card-title")
        concat content_tag(:div, format_placekey(placekey), class: "placekey-card-id")

        if show_coords
          lat, lng = PlacekeyRails.placekey_to_geo(placekey)
          concat content_tag(:div, "Latitude: #{lat}", class: "placekey-card-lat")
          concat content_tag(:div, "Longitude: #{lng}", class: "placekey-card-lng")
        end

        if show_map
          concat leaflet_map_for_placekey(placekey, height: "200px")
        end

        if block_given?
          concat capture { yield }
        end
      end
    end

    # Generate a link to an external map service showing the placekey location
    def external_map_link_for_placekey(placekey, service = :google_maps, link_text = nil)
      return nil unless placekey.present? && PlacekeyRails.placekey_format_is_valid(placekey)

      lat, lng = PlacekeyRails.placekey_to_geo(placekey)

      url = case service
      when :google_maps
              "https://www.google.com/maps/search/?api=1&query=#{lat},#{lng}"
      when :openstreetmap
              "https://www.openstreetmap.org/?mlat=#{lat}&mlon=#{lng}&zoom=15"
      when :bing_maps
              "https://www.bing.com/maps?cp=#{lat}~#{lng}&lvl=15"
      else
              "https://www.google.com/maps/search/?api=1&query=#{lat},#{lng}"
      end

      link_text ||= "View on #{service.to_s.titleize}"

      link_to link_text, url, target: "_blank", class: "placekey-external-map-link"
    end

    # Format distance between placekeys in a human-readable way
    def format_placekey_distance(distance_meters)
      return nil unless distance_meters.present?

      if distance_meters < 1000
        "#{distance_meters.round(1)} m"
      else
        "#{(distance_meters / 1000.0).round(2)} km"
      end
    end
  end
end
