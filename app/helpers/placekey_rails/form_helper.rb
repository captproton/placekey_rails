module PlacekeyRails
  module FormHelper
    # Generate a Placekey form field with validation and autocomplete
    # @param form [FormBuilder] The form builder instance
    # @param options [Hash] Additional options for the field
    def placekey_field(form, options = {})
      wrapper_options = options.delete(:wrapper) || {}
      wrapper_class = wrapper_options.delete(:class) || "placekey-field-wrapper"

      field_options = {
        pattern: "@[23456789bcdfghjkmnpqrstvwxyzeu]{3}-[23456789bcdfghjkmnpqrstvwxyzeu]{3}-[23456789bcdfghjkmnpqrstvwxyzeu]{3}|[23456789bcdfghjkmnpqrstvwxyz]+-[23456789bcdfghjkmnpqrstvwxyz]+@[23456789bcdfghjkmnpqrstvwxyzeu]{3}-[23456789bcdfghjkmnpqrstvwxyzeu]{3}-[23456789bcdfghjkmnpqrstvwxyzeu]{3}",
        title: "Enter a valid Placekey (e.g. @5vg-7gq-tvz or 227-223@5vg-82n-pgk)",
        class: "placekey-field"
      }.merge(options)

      content_tag(:div, wrapper_options.merge(class: wrapper_class)) do
        concat form.text_field(:placekey, field_options)

        if options[:help]
          concat content_tag(:small, options[:help], class: "placekey-field-help")
        else
          concat content_tag(:small, "Format: @xxx-xxx-xxx or xxx-xxx@xxx-xxx-xxx", class: "placekey-field-help")
        end

        if options[:preview] != false
          preview_id = "placekey-preview-#{SecureRandom.hex(4)}"
          concat content_tag(:div, "", id: preview_id, class: "placekey-preview", data: {
            controller: "placekey-preview",
            placekey_preview_target_value: preview_id,
            placekey_preview_field_value: form.object_name + "[placekey]"
          })
        end
      end
    end

    # Generate coordinate fields that automatically generate a Placekey
    # @param form [FormBuilder] The form builder instance
    # @param options [Hash] Additional options for the fields
    def placekey_coordinate_fields(form, options = {})
      # Extract options with proper defaults
      latitude_options = options[:latitude] || {}
      longitude_options = options[:longitude] || {}
      readonly_placekey = options.fetch(:readonly_placekey, true)
      auto_generate = options.fetch(:auto_generate, true)

      content_tag(:div, class: "placekey-coordinate-fields") do
        placekey_options = {
          class: "placekey-field",
          readonly: readonly_placekey,
          data: { auto_generate: auto_generate }
        }

        safe_join([
          field_group(form, :latitude, "Latitude", latitude_options.merge(class: "placekey-latitude-field")),
          field_group(form, :longitude, "Longitude", longitude_options.merge(class: "placekey-longitude-field")),
          field_group(form, :placekey, "Placekey", placekey_options)
        ])
      end
    end

    # Generate an address form that can lookup a Placekey via the API
    # @param form [FormBuilder] The form builder instance
    # @param options [Hash] Additional options for the fields
    def placekey_address_fields(form, options = {})
      wrapper_classes = [ "placekey-address-wrapper" ]
      wrapper_classes << "placekey-warning" if PlacekeyRails.default_client.nil?
      wrapper_classes << "placekey-compact" if options[:compact_layout]

      content_tag(:div, class: wrapper_classes.join(" ")) do
        safe_join([
          api_warning_message,
          render_address_fields(form, options)
        ].compact)
      end
    end

    private

    def api_warning_message
      return unless PlacekeyRails.default_client.nil?
      content_tag(:div, "API client not configured", class: "placekey-warning-message")
    end

    def render_address_fields(form, options)
      # Use default_fields as a base, then merge in any custom options
      fields = default_fields.merge(options.slice(*default_fields.keys))

      # Extract field classes with proper defaults
      field_classes = options[:field_classes] || {}

      # Extract label customizations with proper defaults
      address_label = options[:address_label] || "Street Address"
      city_label = options[:city_label] || "City"
      region_label = options[:region_label] || "Region"
      postal_code_label = options[:postal_code_label] || "Postal Code"

      content_tag(:div, class: "placekey-fields-container") do
        safe_join([
          field_group(form, fields[:address_field], address_label,
            { class: "placekey-street-address-field" }.merge(field_classes[:address] || {})),
          field_group(form, fields[:city_field], city_label,
            { class: "placekey-city-field" }.merge(field_classes[:city] || {})),
          field_group(form, fields[:region_field], region_label,
            { class: "placekey-region-field" }.merge(field_classes[:region] || {})),
          field_group(form, fields[:postal_code_field], postal_code_label,
            { class: "placekey-postal-code-field" }.merge(field_classes[:postal_code] || {}))
        ])
      end
    end

    def default_fields
      {
        address_field: :street_address,
        city_field: :city,
        region_field: :region,
        postal_code_field: :postal_code
      }
    end

    def field_group(form, field, label_text, field_options = {})
      # Ensure class is properly handled
      css_class = field_options.delete(:class) || ""

      content_tag(:div, class: "placekey-field-group") do
        safe_join([
          form.label(field, label_text),
          form.text_field(field, field_options.merge(class: css_class))
        ])
      end
    end
  end
end
