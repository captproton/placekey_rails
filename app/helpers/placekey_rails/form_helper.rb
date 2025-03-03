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
      content_tag(:div, class: "placekey-coordinate-fields") do
        placekey_options = {
          class: "placekey-field",
          readonly: options.fetch(:readonly_placekey, true),
          data: { auto_generate: options.fetch(:auto_generate, true) }
        }

        safe_join([
          field_group(form, :latitude, "Latitude", class: "placekey-latitude-field"),
          field_group(form, :longitude, "Longitude", class: "placekey-longitude-field"),
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
      fields = default_fields.merge(options.slice(*default_fields.keys))

      content_tag(:div, class: "placekey-fields-container") do
        safe_join([
          field_group(form, fields[:address_field], "Street Address",
            class: "placekey-street-address-field"),
          field_group(form, fields[:city_field], "City",
            class: "placekey-city-field"),
          field_group(form, fields[:region_field], "Region",
            class: "placekey-region-field"),
          field_group(form, fields[:postal_code_field], "Postal Code",
            class: "placekey-postal-code-field")
        ])
      end
    end

    def default_fields
      {
        address_field: :address,
        city_field: :city,
        region_field: :region,
        postal_code_field: :postal_code
      }
    end

    def field_group(form, field, label_text, field_options = {})
      content_tag(:div, class: "placekey-field-group") do
        safe_join([
          form.label(field, label_text),
          form.text_field(field, field_options)
        ])
      end
    end
  end
end
