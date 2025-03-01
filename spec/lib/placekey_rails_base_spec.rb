require 'rails_helper'

RSpec.describe PlacekeyRails do
  before do
    # Mock the H3Adapter module for testing
    stub_const("PlacekeyRails::H3Adapter", Module.new)
    allow(PlacekeyRails::H3Adapter).to receive(:latLngToCell).and_return(123456789)
    allow(PlacekeyRails::H3Adapter).to receive(:cellToLatLng).and_return([37.7371, -122.44283])
    allow(PlacekeyRails::H3Adapter).to receive(:stringToH3).and_return(123456789)
    allow(PlacekeyRails::H3Adapter).to receive(:h3ToString).and_return("8a2830828767fff")
    allow(PlacekeyRails::H3Adapter).to receive(:isValidCell).and_return(true)
  end
  
  it "has constants defined for Placekey encoding" do
    expect(PlacekeyRails::RESOLUTION).to eq(10)
    expect(PlacekeyRails::BASE_RESOLUTION).to eq(12)
    expect(PlacekeyRails::ALPHABET).to eq('23456789bcdfghjkmnpqrstvwxyz')
    expect(PlacekeyRails::ALPHABET_LENGTH).to eq(PlacekeyRails::ALPHABET.length)
    expect(PlacekeyRails::CODE_LENGTH).to eq(9)
    expect(PlacekeyRails::TUPLE_LENGTH).to eq(3)
    expect(PlacekeyRails::PADDING_CHAR).to eq('a')
  end
  
  it "includes replacement map for sensitive character combinations" do
    expect(PlacekeyRails::REPLACEMENT_MAP).to include(["prn", "pre"])
    expect(PlacekeyRails::REPLACEMENT_MAP).to include(["f4nny", "f4nne"])
    expect(PlacekeyRails::REPLACEMENT_MAP).to include(["kkk", "kke"])
  end
  
  describe "convenience methods" do
    before do
      allow(PlacekeyRails::Converter).to receive(:geo_to_placekey).and_return("@5vg-82n-kzz")
      allow(PlacekeyRails::Converter).to receive(:placekey_to_geo).and_return([37.7371, -122.44283])
      allow(PlacekeyRails::Converter).to receive(:h3_to_placekey).and_return("@5vg-82n-kzz")
      allow(PlacekeyRails::Converter).to receive(:placekey_to_h3).and_return("8a2830828767fff")
      allow(PlacekeyRails::Validator).to receive(:placekey_format_is_valid).and_return(true)
      allow(PlacekeyRails::Spatial).to receive(:get_neighboring_placekeys).and_return(Set.new(["@5vg-82n-kzz"]))
      allow(PlacekeyRails::Spatial).to receive(:placekey_distance).and_return(1242.8)
    end
    
    it "provides geo_to_placekey method" do
      expect(PlacekeyRails.geo_to_placekey(37.7371, -122.44283)).to eq("@5vg-82n-kzz")
    end
    
    it "provides placekey_to_geo method" do
      expect(PlacekeyRails.placekey_to_geo("@5vg-82n-kzz")).to eq([37.7371, -122.44283])
    end
    
    it "provides h3_to_placekey method" do
      expect(PlacekeyRails.h3_to_placekey("8a2830828767fff")).to eq("@5vg-82n-kzz")
    end
    
    it "provides placekey_to_h3 method" do
      expect(PlacekeyRails.placekey_to_h3("@5vg-82n-kzz")).to eq("8a2830828767fff")
    end
    
    it "provides placekey_format_is_valid method" do
      expect(PlacekeyRails.placekey_format_is_valid("@5vg-82n-kzz")).to be true
    end
    
    it "provides get_neighboring_placekeys method" do
      expect(PlacekeyRails.get_neighboring_placekeys("@5vg-82n-kzz")).to eq(Set.new(["@5vg-82n-kzz"]))
    end
    
    it "provides placekey_distance method" do
      expect(PlacekeyRails.placekey_distance("@5vg-82n-kzz", "@5vg-7gq-tvz")).to eq(1242.8)
    end
    
    it "provides get_prefix_distance_dict method" do
      expect(PlacekeyRails.get_prefix_distance_dict).to be_a(Hash)
      expect(PlacekeyRails.get_prefix_distance_dict[9]).to eq(63.47)
    end
  end
end