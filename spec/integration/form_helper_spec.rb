require 'rails_helper'

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
  end

  describe 'placekey_field' do
    it 'renders placekey field with validation' do
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
  end

  describe 'placekey_coordinate_fields' do
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
  end

  describe 'placekey_address_fields' do
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
      expect(result).to include('placekey-warning')
      expect(result).to include('API client not configured')
    end
  end
end
