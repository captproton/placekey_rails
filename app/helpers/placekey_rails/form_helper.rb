module PlacekeyRails
  module FormHelper
    # Generate a Placekey form field with validation and autocomplete
    # @param form [FormBuilder] The form builder instance
    # @param options [Hash] Additional options for the field
    def placekey_field(form, options = {})
      wrapper_options = options.delete(:wrapper) || {}
      wrapper_class = wrapper_options.delete(:class) || "placekey-field-wrapper"
      
      field_options = {
        pattern: '@[23456789bcdfghjkmnpqrstvwxyzeu]{3}-[23456789bcdfghjkmnpqrstvwxyzeu]{3}-[23456789bcdfghjkmnpqrstvwxyzeu]{3}|[23456789bcdfghjkmnpqrstvwxyz]+-[23456789bcdfghjkmnpqrstvwxyz]+@[23456789bcdfghjkmnpqrstvwxyzeu]{3}-[23456789bcdfghjkmnpqrstvwxyzeu]{3}-[23456789bcdfghjkmnpqrstvwxyzeu]{3}',
        title: 'Enter a valid Placekey (e.g. @5vg-7gq-tvz or 227-223@5vg-82n-pgk)',
        class: 'placekey-field'
      }.merge(options)
      
      content_tag(:div, wrapper_options.merge(class: wrapper_class)) do
        concat form.text_field(:placekey, field_options)
        
        if options[:help]
          concat content_tag(:small, options[:help], class: 'placekey-field-help')
        else
          concat content_tag(:small, 'Format: @xxx-xxx-xxx or xxx-xxx@xxx-xxx-xxx', class: 'placekey-field-help')
        end
        
        if options[:preview] != false
          preview_id = "placekey-preview-#{SecureRandom.hex(4)}"
          concat content_tag(:div, '', id: preview_id, class: 'placekey-preview', data: { 
            controller: 'placekey-preview',
            placekey_preview_target_value: preview_id,
            placekey_preview_field_value: form.object_name + '[placekey]'
          })
        end
      end
    end
    
    # Generate coordinate fields that automatically generate a Placekey
    # @param form [FormBuilder] The form builder instance
    # @param options [Hash] Additional options for the fields
    def placekey_coordinate_fields(form, options = {})
      wrapper_options = options.delete(:wrapper) || {}
      wrapper_class = wrapper_options.delete(:class) || "placekey-coordinates-wrapper"
      
      # Process specific field options
      lat_options = (options.delete(:latitude) || {}).dup
      lat_options[:class] = [lat_options[:class], 'placekey-latitude-field'].compact.join(' ')
      
      lng_options = (options.delete(:longitude) || {}).dup
      lng_options[:class] = [lng_options[:class], 'placekey-longitude-field'].compact.join(' ')
      
      placekey_options = (options.delete(:placekey) || {}).dup
      placekey_options[:readonly] = options[:readonly_placekey].nil? ? true : options[:readonly_placekey]
      placekey_options[:class] = [placekey_options[:class], 'placekey-field'].compact.join(' ')
      
      auto_generate = options[:auto_generate].nil? ? true : options[:auto_generate]
      
      content_tag(:div, wrapper_options.merge(class: wrapper_class)) do
        if auto_generate
          data_attrs = {
            controller: 'placekey-generator',
            placekey_generator_lat_field_value: form.object_name + '[latitude]',
            placekey_generator_lng_field_value: form.object_name + '[longitude]',
            placekey_generator_placekey_field_value: form.object_name + '[placekey]'
          }
          concat content_tag(:div, '', data: data_attrs)
        end
        
        # Latitude field
        concat content_tag(:div, class: 'placekey-field-group') do
          concat form.label(:latitude, options[:latitude_label] || 'Latitude')
          concat form.text_field(:latitude, lat_options)
        end
        
        # Longitude field
        concat content_tag(:div, class: 'placekey-field-group') do
          concat form.label(:longitude, options[:longitude_label] || 'Longitude')
          concat form.text_field(:longitude, lng_options)
        end
        
        # Placekey field
        concat content_tag(:div, class: 'placekey-field-group') do
          concat form.label(:placekey, options[:placekey_label] || 'Placekey')
          concat form.text_field(:placekey, placekey_options)
          
          if options[:help]
            concat content_tag(:small, options[:help], class: 'placekey-field-help')
          elsif auto_generate
            concat content_tag(:small, 'Automatically generated from coordinates', class: 'placekey-field-help')
          end
        end
        
        if options[:preview] != false
          preview_id = "placekey-preview-#{SecureRandom.hex(4)}"
          concat content_tag(:div, '', id: preview_id, class: 'placekey-preview', data: { 
            controller: 'placekey-preview',
            placekey_preview_target_value: preview_id,
            placekey_preview_field_value: form.object_name + '[placekey]'
          })
        end
      end
    end
    
    # Generate an address form that can lookup a Placekey via the API
    # @param form [FormBuilder] The form builder instance
    # @param options [Hash] Additional options for the fields
    def placekey_address_fields(form, options = {})
      wrapper_options = options.delete(:wrapper) || {}
      wrapper_class = wrapper_options.delete(:class) || "placekey-address-wrapper"
      
      # Field name mappings (allows customization of field names)
      address_field = options[:address_field] || :street_address
      city_field = options[:city_field] || :city
      region_field = options[:region_field] || :region
      postal_code_field = options[:postal_code_field] || :postal_code
      country_field = options[:country_field] || :country
      
      # Field configurations
      address_options = (options.delete(:street_address) || {}).merge(
        class: 'placekey-street-address-field'
      )
      
      city_options = (options.delete(:city) || {}).merge(
        class: 'placekey-city-field'
      )
      
      region_options = (options.delete(:region) || {}).merge(
        class: 'placekey-region-field'
      )
      
      postal_code_options = (options.delete(:postal_code) || {}).merge(
        class: 'placekey-postal-code-field'
      )
      
      country_options = (options.delete(:country) || {}).merge(
        class: 'placekey-country-field'
      )
      
      placekey_options = (options.delete(:placekey) || {}).merge(
        class: 'placekey-field'
      )
      
      show_lookup_button = options[:lookup_button].nil? ? true : options[:lookup_button]
      
      content_tag(:div, wrapper_options.merge(class: wrapper_class)) do
        if PlacekeyRails.default_client.nil?
          concat content_tag(:div, "Placekey API client not configured. Call PlacekeyRails.setup_client(api_key) to enable address lookup.", class: 'placekey-api-warning')
        else
          lookup_id = "placekey-lookup-#{SecureRandom.hex(4)}"
          
          data_attrs = {
            controller: 'placekey-lookup',
            placekey_lookup_id_value: lookup_id,
            placekey_lookup_address_field_value: form.object_name + "[#{address_field}]",
            placekey_lookup_city_field_value: form.object_name + "[#{city_field}]",
            placekey_lookup_region_field_value: form.object_name + "[#{region_field}]",
            placekey_lookup_postal_code_field_value: form.object_name + "[#{postal_code_field}]",
            placekey_lookup_country_field_value: form.object_name + "[#{country_field}]",
            placekey_lookup_placekey_field_value: form.object_name + '[placekey]'
          }
          
          concat content_tag(:div, '', id: lookup_id, data: data_attrs)
        end
        
        # Address fields
        concat content_tag(:div, class: 'placekey-field-group') do
          concat form.label(address_field, options[:address_label] || 'Street Address')
          concat form.text_field(address_field, address_options)
        end
        
        # City, region, postal code in a row if compact layout
        if options[:compact_layout]
          concat content_tag(:div, class: 'placekey-field-row') do
            concat content_tag(:div, class: 'placekey-field-group') do
              concat form.label(city_field, options[:city_label] || 'City')
              concat form.text_field(city_field, city_options)
            end
            
            concat content_tag(:div, class: 'placekey-field-group') do
              concat form.label(region_field, options[:region_label] || 'State/Region')
              concat form.text_field(region_field, region_options)
            end
            
            concat content_tag(:div, class: 'placekey-field-group') do
              concat form.label(postal_code_field, options[:postal_code_label] || 'ZIP/Postal Code')
              concat form.text_field(postal_code_field, postal_code_options)
            end
          end
        else
          # Standard layout with each field on its own line
          concat content_tag(:div, class: 'placekey-field-group') do
            concat form.label(city_field, options[:city_label] || 'City')
            concat form.text_field(city_field, city_options)
          end
          
          concat content_tag(:div, class: 'placekey-field-group') do
            concat form.label(region_field, options[:region_label] || 'State/Region')
            concat form.text_field(region_field, region_options)
          end
          
          concat content_tag(:div, class: 'placekey-field-group') do
            concat form.label(postal_code_field, options[:postal_code_label] || 'ZIP/Postal Code')
            concat form.text_field(postal_code_field, postal_code_options)
          end
        end
        
        # Country field
        concat content_tag(:div, class: 'placekey-field-group') do
          concat form.label(country_field, options[:country_label] || 'Country')
          concat form.text_field(country_field, country_options)
        end
        
        # Placekey field
        concat content_tag(:div, class: 'placekey-field-group') do
          concat form.label(:placekey, options[:placekey_label] || 'Placekey')
          concat form.text_field(:placekey, placekey_options)
          
          if options[:help]
            concat content_tag(:small, options[:help], class: 'placekey-field-help')
          else
            concat content_tag(:small, 'Lookup from address or enter manually', class: 'placekey-field-help')
          end
        end
        
        # Lookup button
        if show_lookup_button && PlacekeyRails.default_client
          concat content_tag(:div, class: 'placekey-button-group') do
            button = button_tag('Lookup Placekey', type: 'button', class: 'placekey-lookup-button', data: {
              action: 'placekey-lookup#lookup'
            })
            concat button
          end
        end
        
        # Preview map
        if options[:preview] != false
          preview_id = "placekey-preview-#{SecureRandom.hex(4)}"
          concat content_tag(:div, '', id: preview_id, class: 'placekey-preview', data: { 
            controller: 'placekey-preview',
            placekey_preview_target_value: preview_id,
            placekey_preview_field_value: form.object_name + '[placekey]'
          })
        end
      end
    end
  end
end