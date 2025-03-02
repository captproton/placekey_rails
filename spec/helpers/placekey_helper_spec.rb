require 'rails_helper'

RSpec.describe PlacekeyRails::PlacekeyHelper, type: :helper do
  include PlacekeyRails::PlacekeyHelper

  let(:simple_placekey) { "@5vg-82n-kzz" }
  let(:complex_placekey) { "abc-123@5vg-82n-kzz" }

  describe "#format_placekey" do
    it "formats a simple placekey" do
      result = helper.format_placekey(simple_placekey)
      expect(result).to match(/<span class="placekey">@5vg-82n-kzz<\/span>/)
    end

    it "formats a complex placekey with what/where parts" do
      result = helper.format_placekey(complex_placekey)
      expect(result).to include('<span class="placekey-what">abc-123</span>')
      expect(result).to include('<span class="placekey-separator">@</span>')
      expect(result).to include('<span class="placekey-where">5vg-82n-kzz</span>')
    end

    it "applies custom classes" do
      result = helper.format_placekey(complex_placekey, what_class: "custom-what", where_class: "custom-where")
      expect(result).to include('<span class="custom-what">abc-123</span>')
      expect(result).to include('<span class="custom-where">5vg-82n-kzz</span>')
    end

    it "returns empty string for nil placekey" do
      expect(helper.format_placekey(nil)).to eq("")
    end
  end

  describe "#format_placekey_distance" do
    it "formats distance in meters when less than 1km" do
      result = helper.format_placekey_distance(750)
      expect(result).to eq("750.0 m")
    end

    it "formats distance in kilometers when 1km or more" do
      result = helper.format_placekey_distance(1500)
      expect(result).to eq("1.5 km")
    end

    it "returns nil for nil distance" do
      expect(helper.format_placekey_distance(nil)).to be_nil
    end
  end

  describe "#placekey_map_data" do
    it "generates map data for a valid placekey" do
      result = helper.placekey_map_data(simple_placekey)

      expect(result).to be_a(Hash)
      expect(result[:placekey]).to eq(simple_placekey)
      expect(result[:center]).to be_a(Hash)
      expect(result[:center][:lat]).to be_within(0.001).of(37.7371)
      expect(result[:center][:lng]).to be_within(0.001).of(-122.44283)
      expect(result[:boundary]).to be_an(Array)
      expect(result[:geojson]).to be_a(Hash)
    end

    it "returns empty hash for invalid placekey" do
      expect(helper.placekey_map_data("invalid")).to eq({})
    end

    it "returns empty hash for nil placekey" do
      expect(helper.placekey_map_data(nil)).to eq({})
    end
  end

  describe "#placekeys_map_data" do
    it "generates map data for a collection of placekeys" do
      placekeys = [ simple_placekey, "@5vg-7gq-tvz" ]
      result = helper.placekeys_map_data(placekeys)

      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
      expect(result.first[:placekey]).to eq(simple_placekey)
    end

    it "returns empty array for nil placekeys" do
      expect(helper.placekeys_map_data(nil)).to eq([])
    end

    it "ignores invalid placekeys" do
      placekeys = [ simple_placekey, "invalid" ]
      result = helper.placekeys_map_data(placekeys)

      expect(result).to be_an(Array)
      expect(result.size).to eq(1)
      expect(result.first[:placekey]).to eq(simple_placekey)
    end
  end

  describe "#leaflet_map_for_placekey" do
    it "generates a map div with data attributes" do
      result = helper.leaflet_map_for_placekey(simple_placekey)

      expect(result).to match(/<div.*data-controller="placekey-map"/)
      expect(result).to match(/data-placekey-map-data-value=/)
      expect(result).to include(simple_placekey)
    end

    it "applies custom options" do
      result = helper.leaflet_map_for_placekey(simple_placekey,
                                              height: "300px",
                                              width: "50%",
                                              zoom: 12,
                                              container_id: "custom-map")

      expect(result).to match(/id="custom-map"/)
      expect(result).to match(/style="height: 300px; width: 50%;/)
      expect(result).to match(/data-placekey-map-zoom-value="12"/)
    end

    it "returns nil for invalid placekey" do
      expect(helper.leaflet_map_for_placekey("invalid")).to be_nil
    end
  end

  describe "#placekey_card" do
    it "generates a card with placekey info" do
      result = helper.placekey_card(simple_placekey)

      expect(result).to match(/<div class="placekey-card">/)
      expect(result).to match(/<h3 class="placekey-card-title">/)
      expect(result).to include(simple_placekey)
      expect(result).to match(/Latitude:/)
      expect(result).to match(/Longitude:/)
    end

    it "applies custom options" do
      result = helper.placekey_card(simple_placekey,
                                   title: "Custom Title",
                                   show_coords: false,
                                   show_map: false)

      expect(result).to include("Custom Title")
      expect(result).not_to match(/Latitude:/)
      expect(result).not_to match(/Longitude:/)
      expect(result).not_to match(/data-controller="placekey-map"/)
    end

    it "accepts block content" do
      result = helper.placekey_card(simple_placekey) do
        content_tag(:div, "Custom content", class: "custom-content")
      end

      expect(result).to include('<div class="custom-content">Custom content</div>')
    end

    it "returns nil for invalid placekey" do
      expect(helper.placekey_card("invalid")).to be_nil
    end
  end

  describe "#external_map_link_for_placekey" do
    it "generates a Google Maps link by default" do
      result = helper.external_map_link_for_placekey(simple_placekey)

      expect(result).to match(/<a.*href="https:\/\/www\.google\.com\/maps\/search/)
      expect(result).to match(/target="_blank"/)
      expect(result).to include("View on Google Maps")
    end

    it "generates links for different map services" do
      result = helper.external_map_link_for_placekey(simple_placekey, :openstreetmap)
      expect(result).to match(/href="https:\/\/www\.openstreetmap\.org/)

      result = helper.external_map_link_for_placekey(simple_placekey, :bing_maps)
      expect(result).to match(/href="https:\/\/www\.bing\.com\/maps/)
    end

    it "uses custom link text" do
      result = helper.external_map_link_for_placekey(simple_placekey, :google_maps, "Custom Link")
      expect(result).to include("Custom Link")
    end

    it "returns nil for invalid placekey" do
      expect(helper.external_map_link_for_placekey("invalid")).to be_nil
    end
  end
end
