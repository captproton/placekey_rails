require 'rails_helper'

RSpec.describe PlacekeyRails::FormHelper, type: :helper do
  let(:form_object) { double('form_object') }
  let(:form_builder) { double('form_builder', object_name: 'place', object: form_object) }
  
  before do
    # Setup form_builder double with necessary methods
    allow(form_builder).to receive(:text_field).and_return('<input type="text">')
    allow(form_builder).to receive(:label).and_return('<label></label>')
    
    # Allow SecureRandom to be deterministic for testing
    allow(SecureRandom).to receive(:hex).and_return('1234')
    
    # Stub content_tag and concat to return HTML-like strings for testing
    allow(helper).to receive(:content_tag) do |tag, content = nil, options = nil, &block|
      options_str = options ? " #{options.map{|k,v| "#{k}=\"#{v}\""}.join(' ')}" : ""
      if block_given?
        "<#{tag}#{options_str}>#{block.call}</#{tag}>"
      else
        "<#{tag}#{options_str}>#{content}</#{tag}>"
      end
    end
    
    allow(helper).to receive(:concat) do |content|
      content.to_s
    end
    
    allow(helper).to receive(:link_to) do |text, url, options = {}|
      options_str = options ? " #{options.map{|k,v| "#{k}=\"#{v}\""}.join(' ')}" : ""
      "<a href=\"#{url}\"#{options_str}>#{text}</a>"
    end
    
    allow(helper).to receive(:button_tag) do |text, options = {}|
      options_str = options ? " #{options.map{|k,v| "#{k}=\"#{v}\""}.join(' ')}" : ""
      "<button#{options_str}>#{text}</button>"
    end
    
    # Allow PlacekeyRails.default_client to return a double
    allow(PlacekeyRails).to receive(:default_client).and_return(double('client'))
  end

  describe '#placekey_field' do
    it 'generates a placekey input field with pattern validation' do
      # Don't check details of the pattern, just verify it's called with a pattern
      expect(form_builder).to receive(:text_field).with(
        :placekey, 
        hash_including(:pattern, :class => 'placekey-field')
      ).and_return('<input type="text">')
      
      result = helper.placekey_field(form_builder)
      expect(result).to include('placekey-field-wrapper')
      expect(result).to include('placekey-field-help')
    end
    
    it 'includes preview element by default' do
      result = helper.placekey_field(form_builder)
      expect(result).to include('placekey-preview')
      expect(result).to include('data-controller="placekey-preview"')
      expect(result).to include('data-placekey-preview-field-value="place[placekey]"')
    end
    
    it 'skips preview when preview option is false' do
      result = helper.placekey_field(form_builder, preview: false)
      expect(result).not_to include('placekey-preview')
    end
    
    it 'uses custom help text when provided' do
      result = helper.placekey_field(form_builder, help: 'Custom help text')
      expect(result).to include('Custom help text')
    end
  end
  
  describe '#placekey_coordinate_fields' do
    before do
      # Additional setup for coordinate fields
      allow(form_builder).to receive(:object_name).and_return('place')
    end
    
    it 'generates latitude, longitude, and placekey fields' do
      expect(form_builder).to receive(:text_field).with(:latitude, hash_including(:class => 'placekey-latitude-field')).and_return('<input type="text">')
      expect(form_builder).to receive(:text_field).with(:longitude, hash_including(:class => 'placekey-longitude-field')).and_return('<input type="text">')
      expect(form_builder).to receive(:text_field).with(:placekey, hash_including(:readonly => true)).and_return('<input type="text">')
      
      result = helper.placekey_coordinate_fields(form_builder)
      expect(result).to include('placekey-coordinates-wrapper')
      expect(result).to include('data-controller="placekey-generator"')
    end
    
    it 'allows customization of field options' do
      latitude_options = { placeholder: 'Enter latitude', class: 'custom-lat' }
      longitude_options = { placeholder: 'Enter longitude', class: 'custom-lng' }
      
      expect(form_builder).to receive(:text_field).with(
        :latitude, 
        hash_including(:placeholder => 'Enter latitude')
      ).and_return('<input type="text">')
      
      expect(form_builder).to receive(:text_field).with(
        :longitude, 
        hash_including(:placeholder => 'Enter longitude')
      ).and_return('<input type="text">')
      
      expect(form_builder).to receive(:text_field).with(
        :placekey,
        anything
      ).and_return('<input type="text">')
      
      helper.placekey_coordinate_fields(
        form_builder, 
        latitude: latitude_options,
        longitude: longitude_options
      )
    end
    
    it 'allows disabling auto-generation' do
      expect(form_builder).to receive(:text_field).with(:latitude, anything).and_return('<input type="text">')
      expect(form_builder).to receive(:text_field).with(:longitude, anything).and_return('<input type="text">')
      expect(form_builder).to receive(:text_field).with(:placekey, anything).and_return('<input type="text">')
      
      result = helper.placekey_coordinate_fields(form_builder, auto_generate: false)
      expect(result).not_to include('data-controller="placekey-generator"')
    end
    
    it 'allows non-readonly placekey field' do
      expect(form_builder).to receive(:text_field).with(:latitude, anything).and_return('<input type="text">')
      expect(form_builder).to receive(:text_field).with(:longitude, anything).and_return('<input type="text">')
      expect(form_builder).to receive(:text_field).with(:placekey, hash_including(:readonly => false)).and_return('<input type="text">')
      
      helper.placekey_coordinate_fields(form_builder, readonly_placekey: false)
    end
  end
  
  describe '#placekey_address_fields' do
    before do
      # Setup for address fields
      allow(form_builder).to receive(:text_field).and_return('<input type="text">')
      allow(form_builder).to receive(:object_name).and_return('place')
    end
    
    it 'generates address form fields' do
      fields = [:street_address, :city, :region, :postal_code, :country, :placekey]
      fields.each do |field|
        expect(form_builder).to receive(:text_field).with(field, anything).and_return('<input type="text">').at_least(:once)
        expect(form_builder).to receive(:label).with(field, anything).and_return('<label></label>').at_least(:once)
      end
      
      result = helper.placekey_address_fields(form_builder)
      expect(result).to include('placekey-address-wrapper')
      expect(result).to include('data-controller="placekey-lookup"')
    end
    
    it 'includes lookup button by default' do
      fields = [:street_address, :city, :region, :postal_code, :country, :placekey]
      fields.each do |field|
        allow(form_builder).to receive(:text_field).with(field, anything).and_return('<input type="text">')
        allow(form_builder).to receive(:label).with(field, anything).and_return('<label></label>')
      end
      
      result = helper.placekey_address_fields(form_builder)
      expect(result).to include('button class="placekey-lookup-button"')
      expect(result).to include('data-action="placekey-lookup#lookup"')
    end
    
    it 'shows warning when API client not configured' do
      allow(PlacekeyRails).to receive(:default_client).and_return(nil)
      result = helper.placekey_address_fields(form_builder)
      expect(result).to include('placekey-api-warning')
      expect(result).not_to include('data-controller="placekey-lookup"')
    end
    
    it 'supports compact layout' do
      fields = [:street_address, :city, :region, :postal_code, :country, :placekey]
      fields.each do |field|
        allow(form_builder).to receive(:text_field).with(field, anything).and_return('<input type="text">')
        allow(form_builder).to receive(:label).with(field, anything).and_return('<label></label>')
      end
      
      result = helper.placekey_address_fields(form_builder, compact_layout: true)
      expect(result).to include('placekey-field-row')
    end
    
    it 'allows custom field mapping' do
      expect(form_builder).to receive(:text_field).with(:address, anything).and_return('<input type="text">').at_least(:once)
      expect(form_builder).to receive(:label).with(:address, anything).and_return('<label></label>').at_least(:once)
      
      # Also allow other field calls that will happen
      [:city, :region, :postal_code, :country, :placekey].each do |field|
        allow(form_builder).to receive(:text_field).with(field, anything).and_return('<input type="text">')
        allow(form_builder).to receive(:label).with(field, anything).and_return('<label></label>')
      end
      
      helper.placekey_address_fields(
        form_builder, 
        address_field: :address,
        address_label: 'Address Line'
      )
    end
  end
end
