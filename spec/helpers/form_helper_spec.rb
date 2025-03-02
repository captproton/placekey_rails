require 'rails_helper'

RSpec.describe PlacekeyRails::FormHelper, type: :helper do
  let(:form_object) { double('form_object') }
  let(:form_builder) { double('form_builder', object_name: 'place') }
  
  before do
    # Setup form_builder double with necessary methods
    allow(form_builder).to receive(:text_field).and_return('<input type="text">')
    allow(form_builder).to receive(:label).and_return('<label></label>')
    allow(form_builder).to receive(:object).and_return(form_object)
    
    # Allow SecureRandom to be deterministic for testing
    allow(SecureRandom).to receive(:hex).and_return('1234')
  end

  describe '#placekey_field' do
    it 'generates a placekey input field with pattern validation' do
      expect(form_builder).to receive(:text_field).with(
        :placekey, 
        hash_including(
          pattern: /@[23456789bcdfghjkmnpqrstvwxyzeu]{3}-[23456789bcdfghjkmnpqrstvwxyzeu]{3}-[23456789bcdfghjkmnpqrstvwxyzeu]{3}|[23456789bcdfghjkmnpqrstvwxyz]+-[23456789bcdfghjkmnpqrstvwxyz]+@[23456789bcdfghjkmnpqrstvwxyzeu]{3}-[23456789bcdfghjkmnpqrstvwxyzeu]{3}-[23456789bcdfghjkmnpqrstvwxyzeu]{3}/,
          class: 'placekey-field'
        )
      )
      
      result = helper.placekey_field(form_builder)
      expect(result).to have_css('div.placekey-field-wrapper')
      expect(result).to have_css('small.placekey-field-help')
    end
    
    it 'includes preview element by default' do
      result = helper.placekey_field(form_builder)
      expect(result).to have_css('div.placekey-preview')
      expect(result).to have_css('div[data-controller="placekey-preview"]')
      expect(result).to have_css('div[data-placekey-preview-field-value="place[placekey]"]')
    end
    
    it 'skips preview when preview option is false' do
      result = helper.placekey_field(form_builder, preview: false)
      expect(result).not_to have_css('div.placekey-preview')
    end
    
    it 'uses custom help text when provided' do
      result = helper.placekey_field(form_builder, help: 'Custom help text')
      expect(result).to have_css('small.placekey-field-help', text: 'Custom help text')
    end
  end
  
  describe '#placekey_coordinate_fields' do
    before do
      # Additional setup for coordinate fields
      allow(form_builder).to receive(:object_name).and_return('place')
    end
    
    it 'generates latitude, longitude, and placekey fields' do
      expect(form_builder).to receive(:text_field).with(:latitude, hash_including(class: 'placekey-latitude-field'))
      expect(form_builder).to receive(:text_field).with(:longitude, hash_including(class: 'placekey-longitude-field'))
      expect(form_builder).to receive(:text_field).with(:placekey, hash_including(readonly: true))
      
      result = helper.placekey_coordinate_fields(form_builder)
      expect(result).to have_css('div.placekey-coordinates-wrapper')
      expect(result).to have_css('div[data-controller="placekey-generator"]')
    end
    
    it 'allows customization of field options' do
      latitude_options = { placeholder: 'Enter latitude', class: 'custom-lat' }
      longitude_options = { placeholder: 'Enter longitude', class: 'custom-lng' }
      
      expect(form_builder).to receive(:text_field).with(
        :latitude, 
        hash_including(placeholder: 'Enter latitude', class: 'placekey-latitude-field custom-lat')
      )
      
      expect(form_builder).to receive(:text_field).with(
        :longitude, 
        hash_including(placeholder: 'Enter longitude', class: 'placekey-longitude-field custom-lng')
      )
      
      helper.placekey_coordinate_fields(
        form_builder, 
        latitude: latitude_options,
        longitude: longitude_options
      )
    end
    
    it 'allows disabling auto-generation' do
      result = helper.placekey_coordinate_fields(form_builder, auto_generate: false)
      expect(result).not_to have_css('div[data-controller="placekey-generator"]')
    end
    
    it 'allows non-readonly placekey field' do
      expect(form_builder).to receive(:text_field).with(:placekey, hash_including(readonly: false))
      helper.placekey_coordinate_fields(form_builder, readonly_placekey: false)
    end
  end
  
  describe '#placekey_address_fields' do
    before do
      # Setup for address fields
      allow(PlacekeyRails).to receive(:default_client).and_return(double('client'))
      
      # Form field mocks
      allow(form_builder).to receive(:text_field).and_return('<input type="text">')
      allow(form_builder).to receive(:object_name).and_return('place')
    end
    
    it 'generates address form fields' do
      fields = [:street_address, :city, :region, :postal_code, :country, :placekey]
      fields.each do |field|
        expect(form_builder).to receive(:text_field).with(field, anything).at_least(:once)
      end
      
      result = helper.placekey_address_fields(form_builder)
      expect(result).to have_css('div.placekey-address-wrapper')
      expect(result).to have_css('div[data-controller="placekey-lookup"]')
    end
    
    it 'includes lookup button by default' do
      result = helper.placekey_address_fields(form_builder)
      expect(result).to have_css('button.placekey-lookup-button')
      expect(result).to have_css('button[data-action="placekey-lookup#lookup"]')
    end
    
    it 'shows warning when API client not configured' do
      allow(PlacekeyRails).to receive(:default_client).and_return(nil)
      result = helper.placekey_address_fields(form_builder)
      expect(result).to have_css('div.placekey-api-warning')
      expect(result).not_to have_css('div[data-controller="placekey-lookup"]')
    end
    
    it 'supports compact layout' do
      result = helper.placekey_address_fields(form_builder, compact_layout: true)
      expect(result).to have_css('div.placekey-field-row')
    end
    
    it 'allows custom field mapping' do
      expect(form_builder).to receive(:text_field).with(:address, anything)
      expect(form_builder).to receive(:label).with(:address, anything)
      
      helper.placekey_address_fields(
        form_builder, 
        address_field: :address,
        address_label: 'Address Line'
      )
    end
  end
end
