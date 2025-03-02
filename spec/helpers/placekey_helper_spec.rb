require 'rails_helper'

RSpec.describe PlacekeyRails::PlacekeyHelper, type: :helper do
  before do
    allow(PlacekeyRails::Converter).to receive(:parse_placekey).with('@5vg-7gq-tvz').and_return([nil, '5vg-7gq-tvz'])
    allow(PlacekeyRails::Converter).to receive(:parse_placekey).with('227-223@5vg-82n-pgk').and_return(['227-223', '5vg-82n-pgk'])
    allow(PlacekeyRails).to receive(:placekey_format_is_valid).with('@5vg-7gq-tvz').and_return(true)
    allow(PlacekeyRails).to receive(:placekey_format_is_valid).with('invalid-format').and_return(false)
    allow(PlacekeyRails).to receive(:placekey_to_geo).with('@5vg-7gq-tvz').and_return([37.7371, -122.44283])
    allow(PlacekeyRails).to receive(:placekey_to_hex_boundary).and_return([[37.7, -122.4], [37.7, -122.5]])
    allow(PlacekeyRails).to receive(:placekey_to_geojson).and_return({ "type" => "Polygon" })
  end

  describe '#format_placekey' do
    it 'returns empty string for nil placekey' do
      expect(helper.format_placekey(nil)).to eq('')
    end

    it 'formats a placekey without what part' do
      result = helper.format_placekey('@5vg-7gq-tvz')
      expect(result).to have_css('span.placekey', text: '@5vg-7gq-tvz')
    end

    it 'formats a placekey with what part using different classes' do
      result = helper.format_placekey('227-223@5vg-82n-pgk')
      expect(result).to have_css('span.placekey')
      expect(result).to have_css('span.placekey-what', text: '227-223')
      expect(result).to have_css('span.placekey-separator', text: '@')
      expect(result).to have_css('span.placekey-where', text: '5vg-82n-pgk')
    end

    it 'respects custom class options' do
      result = helper.format_placekey('227-223@5vg-82n-pgk', what_class: 'custom-what', where_class: 'custom-where')
      expect(result).to have_css('span.custom-what', text: '227-223')
      expect(result).to have_css('span.custom-where', text: '5vg-82n-pgk')
    end
  end

  describe '#placekey_map_data' do
    it 'returns empty hash for invalid placekey' do
      expect(helper.placekey_map_data(nil)).to eq({})
      expect(helper.placekey_map_data('invalid-format')).to eq({})
    end

    it 'returns map data for valid placekey' do
      result = helper.placekey_map_data('@5vg-7gq-tvz')
      expect(result[:placekey]).to eq('@5vg-7gq-tvz')
      expect(result[:center]).to eq({ lat: 37.7371, lng: -122.44283 })
      expect(result[:boundary]).to be_present
      expect(result[:geojson]).to be_present
    end
  end

  describe '#placekeys_map_data' do
    it 'returns empty array for nil placekeys' do
      expect(helper.placekeys_map_data(nil)).to eq([])
    end

    it 'returns map data for array of placekeys' do
      result = helper.placekeys_map_data(['@5vg-7gq-tvz'])
      expect(result).to be_an(Array)
      expect(result.first[:placekey]).to eq('@5vg-7gq-tvz')
    end
  end

  describe '#leaflet_map_for_placekey' do
    it 'returns nil for invalid placekey' do
      expect(helper.leaflet_map_for_placekey(nil)).to be_nil
      expect(helper.leaflet_map_for_placekey('invalid-format')).to be_nil
    end

    it 'returns map container with data attributes' do
      result = helper.leaflet_map_for_placekey('@5vg-7gq-tvz')
      expect(result).to have_css('div[id^="placekey-map"]')
      expect(result).to have_css('div[data-controller="placekey-map"]')
      expect(result).to have_css('div[data-placekey-map-zoom-value="15"]')
    end

    it 'respects configuration options' do
      result = helper.leaflet_map_for_placekey('@5vg-7gq-tvz', container_id: 'custom-id', height: '500px', zoom: 12)
      expect(result).to have_css('div#custom-id')
      expect(result).to have_css('div[style*="height: 500px"]')
      expect(result).to have_css('div[data-placekey-map-zoom-value="12"]')
    end
  end

  describe '#placekey_card' do
    it 'returns nil for invalid placekey' do
      expect(helper.placekey_card(nil)).to be_nil
      expect(helper.placekey_card('invalid-format')).to be_nil
    end

    it 'creates a card with default options' do
      result = helper.placekey_card('@5vg-7gq-tvz')
      expect(result).to have_css('div.placekey-card')
      expect(result).to have_css('h3.placekey-card-title', text: 'Placekey Information')
      expect(result).to have_css('div.placekey-card-id')
      expect(result).to have_css('div.placekey-card-lat')
      expect(result).to have_css('div.placekey-card-lng')
    end

    it 'respects show_coords and show_map options' do
      result = helper.placekey_card('@5vg-7gq-tvz', show_coords: false, show_map: false)
      expect(result).not_to have_css('div.placekey-card-lat')
      expect(result).not_to have_css('div.placekey-card-lng')
      expect(result).not_to have_css('div[data-controller="placekey-map"]')
    end

    it 'allows custom title' do
      result = helper.placekey_card('@5vg-7gq-tvz', title: 'Custom Title')
      expect(result).to have_css('h3.placekey-card-title', text: 'Custom Title')
    end

    it 'allows custom content via block' do
      result = helper.placekey_card('@5vg-7gq-tvz') do
        content_tag(:div, 'Custom content', class: 'custom-content')
      end
      expect(result).to have_css('div.custom-content', text: 'Custom content')
    end
  end

  describe '#external_map_link_for_placekey' do
    it 'returns nil for invalid placekey' do
      expect(helper.external_map_link_for_placekey(nil)).to be_nil
      expect(helper.external_map_link_for_placekey('invalid-format')).to be_nil
    end

    it 'creates a Google Maps link by default' do
      result = helper.external_map_link_for_placekey('@5vg-7gq-tvz')
      expect(result).to have_css('a[href*="google.com/maps"]')
      expect(result).to have_css('a[href*="37.7371,-122.44283"]')
      expect(result).to have_css('a', text: 'View on Google Maps')
    end

    it 'creates an OpenStreetMap link when specified' do
      result = helper.external_map_link_for_placekey('@5vg-7gq-tvz', :openstreetmap)
      expect(result).to have_css('a[href*="openstreetmap.org"]')
      expect(result).to have_css('a', text: 'View on Openstreetmap')
    end

    it 'allows custom link text' do
      result = helper.external_map_link_for_placekey('@5vg-7gq-tvz', :google_maps, 'See on Map')
      expect(result).to have_css('a', text: 'See on Map')
    end
  end

  describe '#format_placekey_distance' do
    it 'returns nil for nil distance' do
      expect(helper.format_placekey_distance(nil)).to be_nil
    end

    it 'formats distance in meters when less than 1km' do
      expect(helper.format_placekey_distance(123.4)).to eq('123.4 m')
    end

    it 'formats distance in kilometers when 1km or more' do
      expect(helper.format_placekey_distance(1234.5)).to eq('1.23 km')
    end
  end
end
