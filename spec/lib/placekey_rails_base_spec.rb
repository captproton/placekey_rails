require 'rails_helper'

RSpec.describe PlacekeyRails do
  before do
    # Create a mock H3Adapter module
    adapter_mock = Module.new
    
    # Define mock methods with the correct method names
    adapter_mock.define_singleton_method(:lat_lng_to_cell) { |lat, lng, res| 123456789 }
    adapter_mock.define_singleton_method(:cell_to_lat_lng) { |h3| [37.7371, -122.44283] }
    adapter_mock.define_singleton_method(:string_to_h3) { |str| 123456789 }
    adapter_mock.define_singleton_method(:h3_to_string) { |h3| "8a2830828767fff" }
    adapter_mock.define_singleton_method(:is_valid_cell) { |h3| true }
    
    # Define camelCase methods directly since we can't use method_alias in a dynamic module
    adapter_mock.define_singleton_method(:latLngToCell) { |lat, lng, res| 123456789 }
    adapter_mock.define_singleton_method(:cellToLatLng) { |h3| [37.7371, -122.44283] }
    adapter_mock.define_singleton_method(:stringToH3) { |str| 123456789 }
    adapter_mock.define_singleton_method(:h3ToString) { |h3| "8a2830828767fff" }
    adapter_mock.define_singleton_method(:isValidCell) { |h3| true }
    adapter_mock.define_singleton_method(:gridDisk) { |h3, k| [123456789, 123456790, 123456791] }
    adapter_mock.define_singleton_method(:cellToBoundary) { |h3| [[37.7371, -122.44283], [37.7373, -122.44284], [37.7375, -122.44283], [37.7375, -122.44281], [37.7373, -122.44280], [37.7371, -122.44281]] }
    
    # Stub the H3Adapter constant
    stub_const("PlacekeyRails::H3Adapter", adapter_mock)
    
    # Set up converter and other mocks
    converter_mock = Module.new
    converter_mock.define_singleton_method(:geo_to_placekey) { |lat, lng| "@5vg-82n-kzz" }
    converter_mock.define_singleton_method(:placekey_to_geo) { |placekey| [37.7371, -122.44283] }
    converter_mock.define_singleton_method(:h3_to_placekey) { |h3_string| "@5vg-82n-kzz" }
    converter_mock.define_singleton_method(:placekey_to_h3) { |placekey| "8a2830828767fff" }
    stub_const("PlacekeyRails::Converter", converter_mock)
    
    validator_mock = Module.new
    validator_mock.define_singleton_method(:placekey_format_is_valid) { |placekey| true }
    stub_const("PlacekeyRails::Validator", validator_mock)
    
    spatial_mock = Module.new
    spatial_mock.define_singleton_method(:get_neighboring_placekeys) { |placekey, dist=1| Set.new(["@5vg-82n-kzz"]) }
    spatial_mock.define_singleton_method(:placekey_distance) { |placekey_1, placekey_2| 1242.8 }
    stub_const("PlacekeyRails::Spatial", spatial_mock)
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
