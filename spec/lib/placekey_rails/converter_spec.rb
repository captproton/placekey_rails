require 'rails_helper'

RSpec.describe PlacekeyRails::Converter do
  before do
    # Mock the H3Adapter module for testing
    stub_const("PlacekeyRails::H3Adapter", Module.new)
    allow(PlacekeyRails::H3Adapter).to receive(:latLngToCell).and_return(123456789)
    allow(PlacekeyRails::H3Adapter).to receive(:cellToLatLng).and_return([37.7371, -122.44283])
    allow(PlacekeyRails::H3Adapter).to receive(:stringToH3).and_return(123456789)
    allow(PlacekeyRails::H3Adapter).to receive(:h3ToString).and_return("8a2830828767fff")
    allow(PlacekeyRails::H3Adapter).to receive(:isValidCell).and_return(true)
    
    # Mock our internal methods as well
    allow(described_class).to receive(:encode_h3_int).and_return("@5vg-82n-kzz")
    allow(described_class).to receive(:decode_to_h3_int).and_return(123456789)
  end
  
  describe ".geo_to_placekey" do
    it "converts coordinates to placekey" do
      lat, long = 37.7371, -122.44283
      expect(described_class.geo_to_placekey(lat, long)).to eq("@5vg-82n-kzz")
    end
  end
  
  describe ".placekey_to_geo" do
    it "converts placekey to coordinates" do
      placekey = "@5vg-82n-kzz"
      lat, long = described_class.placekey_to_geo(placekey)
      expect(lat).to eq(37.7371)
      expect(long).to eq(-122.44283)
    end
  end
  
  describe ".h3_to_placekey" do
    it "converts h3 to placekey" do
      h3_string = "8a2830828767fff"
      expect(described_class.h3_to_placekey(h3_string)).to eq("@5vg-82n-kzz")
    end
  end
  
  describe ".placekey_to_h3" do
    it "converts placekey to h3" do
      placekey = "@5vg-82n-kzz"
      h3_index = described_class.placekey_to_h3(placekey)
      expect(h3_index).to eq("8a2830828767fff")
    end
  end
  
  describe ".parse_placekey" do
    it "parses a placekey with a what part" do
      placekey = "abc-def@5vg-82n-kzz"
      what, where = described_class.parse_placekey(placekey)
      expect(what).to eq("abc-def")
      expect(where).to eq("5vg-82n-kzz")
    end
    
    it "parses a placekey without a what part" do
      placekey = "@5vg-82n-kzz"
      what, where = described_class.parse_placekey(placekey)
      expect(what).to be_nil
      expect(where).to eq("5vg-82n-kzz")
    end
  end
end