require 'rails_helper'

RSpec.describe PlacekeyRails::FormHelper, type: :helper do
  include PlacekeyRails::FormHelper

  # We need to create a test form builder
  let(:location) { Location.new }
  let(:template) { ActionView::Base.new }
  let(:form_builder) do
    ActionView::Helpers::FormBuilder.new(:location, location, template, {})
  end

  describe "#placekey_field" do
    it "generates a placekey input field with validation" do
      allow(helper).to receive(:content_tag).and_call_original
      allow(form_builder).to receive(:text_field).and_return('<input type="text" name="location[placekey]" id="location_placekey" />')

      result = helper.placekey_field(form_builder)

      expect(result).to include('class="placekey-field-wrapper"')
      expect(result).to include('<input type="text" name="location[placekey]" id="location_placekey" />')
      expect(result).to include('Format: @xxx-xxx-xxx or xxx-xxx@xxx-xxx-xxx')
    end

    it "applies custom options" do
      allow(helper).to receive(:content_tag).and_call_original
      allow(form_builder).to receive(:text_field).and_return('<input type="text" name="location[placekey]" id="location_placekey" />')

      result = helper.placekey_field(form_builder,
                                    help: "Custom help text",
                                    preview: false,
                                    wrapper: { class: "custom-wrapper" })

      expect(result).to include('class="custom-wrapper"')
      expect(result).to include('Custom help text')
      expect(result).not_to include('placekey-preview')
    end
  end

  describe "#placekey_coordinate_fields" do
    before do
      allow(helper).to receive(:content_tag).and_call_original
      allow(form_builder).to receive(:label).and_return('<label>Field Label</label>')
      allow(form_builder).to receive(:text_field).and_return('<input type="text" />')
    end

    it "generates coordinate fields that auto-generate a placekey" do
      result = helper.placekey_coordinate_fields(form_builder)

      expect(result).to include('class="placekey-coordinates-wrapper"')
      expect(result).to include('data-controller="placekey-generator"')
      expect(result).to include('class="placekey-latitude-field"')
      expect(result).to include('class="placekey-longitude-field"')
      expect(result).to include('class="placekey-field-group"')
    end

    it "applies custom options" do
      result = helper.placekey_coordinate_fields(form_builder,
                                               latitude: { step: "0.0001" },
                                               longitude: { step: "0.0001" },
                                               readonly_placekey: false,
                                               preview: false,
                                               auto_generate: false)

      expect(result).not_to include('data-controller="placekey-generator"')
      expect(result).not_to include('placekey-preview')
    end
  end

  describe "#placekey_address_fields" do
    before do
      allow(helper).to receive(:content_tag).and_call_original
      allow(helper).to receive(:button_tag).and_return('<button>Lookup Placekey</button>')
      allow(form_builder).to receive(:label).and_return('<label>Field Label</label>')
      allow(form_builder).to receive(:text_field).and_return('<input type="text" />')
    end

    it "generates address fields for placekey lookup" do
      result = helper.placekey_address_fields(form_builder)

      expect(result).to include('class="placekey-address-wrapper"')
      expect(result).to include('class="placekey-street-address-field"')
      expect(result).to include('class="placekey-city-field"')
      expect(result).to include('class="placekey-region-field"')
      expect(result).to include('class="placekey-postal-code-field"')
      expect(result).to include('class="placekey-country-field"')
      expect(result).to include('class="placekey-field"')
      expect(result).to include('<button>Lookup Placekey</button>')
    end

    it "applies custom options" do
      result = helper.placekey_address_fields(form_builder,
                                            address_field: :street,
                                            city_field: :town,
                                            region_field: :state,
                                            compact_layout: true,
                                            preview: false,
                                            lookup_button: false)

      expect(result).to include('class="placekey-field-row"')
      expect(result).not_to include('placekey-preview')
      expect(result).not_to include('<button>Lookup Placekey</button>')
    end

    it "shows a warning when API client is not configured" do
      allow(PlacekeyRails).to receive(:default_client).and_return(nil)

      result = helper.placekey_address_fields(form_builder)

      expect(result).to include('Placekey API client not configured')
    end
  end
end
