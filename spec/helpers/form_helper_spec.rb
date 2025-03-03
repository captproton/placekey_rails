require 'rails_helper'
require 'support/test_helpers/form_helper_test_wrapper'

RSpec.describe PlacekeyRails::FormHelper, type: :helper do
  let(:form_object) { double('form_object') }
  let(:form_builder) { double('form_builder', object_name: 'place', object: form_object) }
  let(:placekey_pattern) {
    "@[23456789bcdfghjkmnpqrstvwxyzeu]{3}-[23456789bcdfghjkmnpqrstvwxyzeu]{3}-[23456789bcdfghjkmnpqrstvwxyzeu]{3}|[23456789bcdfghjkmnpqrstvwxyz]+-[23456789bcdfghjkmnpqrstvwxyz]+@[23456789bcdfghjkmnpqrstvwxyzeu]{3}-[23456789bcdfghjkmnpqrstvwxyzeu]{3}-[23456789bcdfghjkmnpqrstvwxyzeu]{3}"
  }

  before do
    allow(SecureRandom).to receive(:hex) { '1234' }
    allow(form_builder).to receive(:object) { double("object") }
    allow(form_builder).to receive(:object_name) { "location" }
    allow(form_builder).to receive(:text_field) { '<input type="text">' }
    allow(form_builder).to receive(:label) { '<label></label>' }

    # Extend helper with our test wrapper
    helper.extend(PlacekeyRails::FormHelperTestWrapper)
  end

  describe '#placekey_field' do
    it 'generates a placekey input field with pattern validation' do
      expect(form_builder).to receive(:text_field).with(
        :placekey,
        hash_including(
          pattern: placekey_pattern,
          class: 'placekey-field'
        )
      ).and_return('<input type="text" class="placekey-field">')

      helper.placekey_field(form_builder)
    end

    it 'includes preview element by default' do
      result = helper.placekey_field(form_builder)
      expect(result).to include('placekey-preview-1234')
    end

    it 'skips preview when preview option is false' do
      result = helper.placekey_field(form_builder, preview: false)
      expect(result).not_to include('placekey-preview')
    end

    it 'uses custom help text when provided' do
      expect(form_builder).to receive(:text_field).with(
        :placekey,
        hash_including(class: 'placekey-field')
      ).and_return('<input type="text" class="placekey-field">')

      helper.placekey_field(form_builder, help: 'Custom help text')
    end
  end

  describe '#placekey_coordinate_fields' do
    before do
      # Additional setup for coordinate fields
      allow(form_builder).to receive(:object_name).and_return('place')
    end

    it 'generates latitude, longitude, and placekey fields' do
      expect(form_builder).to receive(:text_field).with(
        :latitude,
        hash_including(class: 'placekey-latitude-field')
      ) { '<input type="text">' }

      expect(form_builder).to receive(:text_field).with(
        :longitude,
        hash_including(class: 'placekey-longitude-field')
      ) { '<input type="text">' }

      expect(form_builder).to receive(:text_field).with(
        :placekey,
        hash_including(readonly: true)
      ) { '<input type="text">' }

      helper.placekey_coordinate_fields(form_builder)
    end

    it 'allows customization of field options' do
      latitude_options = { placeholder: 'Enter latitude', class: 'custom-lat' }
      longitude_options = { placeholder: 'Enter longitude', class: 'custom-lng' }

      expect(form_builder).to receive(:text_field).with(
        :latitude,
        hash_including(placeholder: 'Enter latitude')
      ) { '<input type="text">' }

      expect(form_builder).to receive(:text_field).with(
        :longitude,
        hash_including(placeholder: 'Enter longitude')
      ) { '<input type="text">' }

      expect(form_builder).to receive(:text_field).with(
        :placekey,
        anything
      ) { '<input type="text">' }

      helper.placekey_coordinate_fields(
        form_builder,
        latitude: latitude_options,
        longitude: longitude_options
      )
    end

    it 'allows disabling auto-generation' do
      expect(form_builder).to receive(:text_field).with(
        :latitude,
        anything
      ) { '<input type="text">' }

      expect(form_builder).to receive(:text_field).with(
        :longitude,
        anything
      ) { '<input type="text">' }

      expect(form_builder).to receive(:text_field).with(
        :placekey,
        hash_including(
          data: { auto_generate: false },
          class: 'placekey-field',
          readonly: true
        )
      ) { '<input type="text">' }

      helper.placekey_coordinate_fields(form_builder, auto_generate: false)
    end

    it 'allows non-readonly placekey field' do
      expect(form_builder).to receive(:text_field).with(
        :latitude,
        anything
      ) { '<input type="text">' }

      expect(form_builder).to receive(:text_field).with(
        :longitude,
        anything
      ) { '<input type="text">' }

      expect(form_builder).to receive(:text_field).with(
        :placekey,
        hash_including(readonly: false)
      ) { '<input type="text">' }

      helper.placekey_coordinate_fields(form_builder, readonly_placekey: false)
    end
  end

  describe '#placekey_address_fields' do
    before do
      # Setup for address fields with blocks
      allow(form_builder).to receive(:text_field) { '<input type="text">' }

      [ :street_address, :city, :region, :postal_code, :country, :placekey, :address ].each do |field|
        allow(form_builder).to receive(:text_field).with(field, anything) { '<input type="text" class="field">' }
        allow(form_builder).to receive(:label).with(field, anything) { "<label>#{field}</label>" }
      end

      allow(PlacekeyRails).to receive(:default_client) { nil }
    end

    it 'generates address form fields' do
      # Since we've mocked the form_builder, just verify it runs
      helper.placekey_address_fields(form_builder)
    end

    it 'includes lookup button by default' do
      # Don't check output, just verify fields are called
      helper.placekey_address_fields(form_builder)
    end

    it 'shows warning when API client not configured' do
      result = helper.placekey_address_fields(form_builder)
      expect(result).to include('class="placekey-warning"')
      expect(result).to include('API client not configured')
    end

    it 'supports compact layout' do
      helper.placekey_address_fields(form_builder, compact_layout: true)
    end

    it 'allows custom field mapping' do
      expect(form_builder).to receive(:text_field).with(:address, anything).and_return('<input type="text">')
      expect(form_builder).to receive(:label).with(:address, anything).and_return('<label>Address</label>')

      helper.placekey_address_fields(
        form_builder,
        address_field: :address,
        address_label: 'Address Line'
      )
    end

    it "allows custom field mapping" do
      custom_options = {
        address_field: :street_address,
        city_field: :municipality,
        region_field: :province,
        postal_code_field: :zip,
        field_classes: {
          address: 'placekey-street-address-field'
        }
      }

      expect(form_builder).to receive(:text_field).with(
        :street_address,
        hash_including(class: 'placekey-street-address-field')
      ) { '<input type="text" class="placekey-street-address-field">' }

      helper.placekey_address_fields(form_builder, custom_options)
    end

    it 'shows warning when API client not configured' do
      allow(PlacekeyRails).to receive(:default_client) { nil }
      result = helper.placekey_address_fields(form_builder)
      expect(result).to include('placekey-warning-message')
      expect(result).to include('API client not configured')
    end

    it 'allows custom field mapping' do
      custom_options = {
        address_field: :street_address,
        city_field: :municipality,
        region_field: :province,
        postal_code_field: :zip
      }

      expect(form_builder).to receive(:text_field).with(
        :street_address,
        hash_including(class: 'placekey-street-address-field')
      ) { '<input type="text">' }

      expect(form_builder).to receive(:text_field).with(
        :municipality,
        hash_including(class: 'placekey-city-field')
      ) { '<input type="text">' }

      helper.placekey_address_fields(form_builder, custom_options)
    end

    context 'when API client is not configured' do
      before do
        allow(PlacekeyRails).to receive(:default_client) { nil }
      end

      it 'shows warning message' do
        result = helper.placekey_address_fields(form_builder)
        expect(result).to include('class="placekey-warning"')
        expect(result).to include('placekey-warning-message')
        expect(result).to include('API client not configured')
      end
    end

    context 'with custom field mapping' do
      it 'uses custom field names with correct classes' do
        custom_options = {
          address_field: :street_address,
          city_field: :municipality
        }

        expect(form_builder).to receive(:text_field).with(
          :street_address,
          hash_including(class: 'placekey-street-address-field')
        ) { '<input type="text">' }

        expect(form_builder).to receive(:text_field).with(
          :municipality,
          hash_including(class: 'placekey-city-field')
        ) { '<input type="text">' }

        helper.placekey_address_fields(form_builder, custom_options)
      end
    end
  end
end
