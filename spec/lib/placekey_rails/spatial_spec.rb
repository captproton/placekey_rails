require 'rails_helper'

RSpec.describe PlacekeyRails::Spatial do
  before do
    # Mock the H3Adapter module for testing
    stub_const("PlacekeyRails::H3Adapter", Module.new)
    allow(PlacekeyRails::H3Adapter).to receive(:latLngToCell).and_return(123456789)
    allow(PlacekeyRails::H3Adapter).to receive(:cellToLatLng).and_return([37.7371, -122.44283])
    allow(PlacekeyRails::H3Adapter).to receive(:stringToH3).and_return(123456789)
    allow(PlacekeyRails::H3Adapter).to receive(:h3ToString).and_return("8a2830828767fff")
    allow(PlacekeyRails::H3Adapter).to receive(:isValidCell).and_return(true)
    allow(PlacekeyRails::H3Adapter).to receive(:gridDisk).and_return([123456789, 123456790, 123456791])
    allow(PlacekeyRails::H3Adapter).to receive(:cellToBoundary).and_return([
      [37.7370, -122.4428],
      [37.7374, -122.4430],
      [37.7378, -122.4428],
      [37.7378, -122.4423],
      [37.7374, -122.4421],
      [37.7370, -122.4423]
    ])
    
    # Mock PlacekeyRails::Converter methods
    allow(PlacekeyRails::Converter).to receive(:placekey_to_h3_int).and_return(123456789)
    allow(PlacekeyRails::Converter).to receive(:h3_int_to_placekey).and_return("@5vg-82n-kzz")
  end
  
  describe ".get_neighboring_placekeys" do
    it "finds neighboring placekeys" do
      placekey = "@5vg-7gq-tvz"
      expected_set = Set.new(["@5vg-82n-kzz", "@5vg-82n-kzz", "@5vg-82n-kzz"])
      result = described_class.get_neighboring_placekeys(placekey, 1)
      expect(result).to eq(expected_set)
    end
  end
  
  describe ".placekey_distance" do
    it "calculates distance between two placekeys" do
      # Instead of mocking the private geo_distance method,
      # let's set expectations on what should happen based on our mock H3Adapter returns
      placekey1 = "@5vg-7gq-tvz"
      placekey2 = "@5vg-82n-kzz"
      
      # Since we've mocked H3Adapter.cellToLatLng to always return the same coordinates,
      # the distance calculation should return 0 (or very close to it)
      result = described_class.placekey_distance(placekey1, placekey2)
      expect(result).to be_within(0.1).of(0.0)
    end
  end
  
  describe ".placekey_to_hex_boundary" do
    it "returns boundary coordinates" do
      placekey = "@5vg-7gq-tvz"
      result = described_class.placekey_to_hex_boundary(placekey)
      
      expect(result).to be_an(Array)
      expect(result.size).to eq(6)
      expect(result.first).to eq([37.7370, -122.4428])
    end
    
    it "returns boundary coordinates in GeoJSON format" do
      placekey = "@5vg-7gq-tvz"
      result = described_class.placekey_to_hex_boundary(placekey, geo_json: true)
      
      expect(result).to be_an(Array)
      expect(result.size).to eq(6)
      expect(result.first).to eq([-122.4428, 37.7370])
    end
  end
  
  describe ".placekey_to_polygon" do
    it "returns a polygon from placekey" do
      # Mock RGeo factories and objects
      factory = instance_double("RGeo::Cartesian::Factory")
      linear_ring = instance_double("RGeo::Cartesian::LinearRing")
      polygon = instance_double("RGeo::Cartesian::Polygon")
      point = instance_double("RGeo::Cartesian::Point")
      
      allow(RGeo::Cartesian).to receive(:factory).and_return(factory)
      allow(factory).to receive(:point).and_return(point)
      allow(factory).to receive(:linear_ring).with(array_including(point)).and_return(linear_ring)
      allow(factory).to receive(:polygon).with(linear_ring).and_return(polygon)
      
      placekey = "@5vg-7gq-tvz"
      result = described_class.placekey_to_polygon(placekey)
      
      expect(result).to eq(polygon)
    end
  end
  
  describe ".placekey_to_wkt" do
    it "converts placekey to WKT" do
      polygon = instance_double("RGeo::Cartesian::Polygon")
      allow(described_class).to receive(:placekey_to_polygon).and_return(polygon)
      allow(polygon).to receive(:as_text).and_return("POLYGON ((-122.4428 37.7370, -122.4430 37.7374, -122.4428 37.7378, -122.4423 37.7378, -122.4421 37.7374, -122.4423 37.7370, -122.4428 37.7370))")
      
      placekey = "@5vg-7gq-tvz"
      result = described_class.placekey_to_wkt(placekey)
      
      expect(result).to eq("POLYGON ((-122.4428 37.7370, -122.4430 37.7374, -122.4428 37.7378, -122.4423 37.7378, -122.4421 37.7374, -122.4423 37.7370, -122.4428 37.7370))")
    end
  end
  
  describe ".placekey_to_geojson" do
    it "converts placekey to GeoJSON" do
      polygon = instance_double("RGeo::Cartesian::Polygon")
      geojson = { "type" => "Polygon", "coordinates" => [[[-122.4428, 37.7370], [-122.4430, 37.7374], [-122.4428, 37.7378], [-122.4423, 37.7378], [-122.4421, 37.7374], [-122.4423, 37.7370], [-122.4428, 37.7370]]] }
      
      allow(described_class).to receive(:placekey_to_polygon).and_return(polygon)
      allow(RGeo::GeoJSON).to receive(:encode).with(polygon).and_return(geojson)
      
      placekey = "@5vg-7gq-tvz"
      result = described_class.placekey_to_geojson(placekey)
      
      expect(result).to eq(geojson)
    end
  end
  
  describe ".polygon_to_placekeys" do
    it "finds placekeys within a polygon" do
      # This is a more complex test that would require more mocking
      # Just test that the method returns a hash with expected keys
      polygon = instance_double("RGeo::Cartesian::Polygon")
      allow(polygon).to receive(:buffer).and_return(polygon)
      allow(PlacekeyRails::H3Adapter).to receive(:polyfill).and_return([123456789, 123456790])
      allow(polygon).to receive(:contains?).and_return(true, false)
      allow(polygon).to receive(:intersects?).and_return(true)
      allow(polygon).to receive(:touches?).and_return(false)
      
      result = described_class.polygon_to_placekeys(polygon)
      
      expect(result).to be_a(Hash)
      expect(result).to have_key(:interior)
      expect(result).to have_key(:boundary)
      expect(result[:interior]).to eq(["@5vg-82n-kzz"])
      expect(result[:boundary]).to eq(["@5vg-82n-kzz"])
    end
  end
  
  describe ".wkt_to_placekeys" do
    it "finds placekeys within a WKT polygon" do
      polygon = instance_double("RGeo::Cartesian::Polygon")
      allow(RGeo::WKT).to receive(:parse).and_return(polygon)
      allow(described_class).to receive(:polygon_to_placekeys).and_return({
        interior: ["@5vg-82n-kzz"],
        boundary: ["@5vg-82n-qqq"]
      })
      
      wkt = "POLYGON ((-122.4428 37.7370, -122.4430 37.7374, -122.4428 37.7378, -122.4423 37.7378, -122.4421 37.7374, -122.4423 37.7370, -122.4428 37.7370))"
      result = described_class.wkt_to_placekeys(wkt)
      
      expect(result).to be_a(Hash)
      expect(result).to have_key(:interior)
      expect(result).to have_key(:boundary)
    end
  end
  
  describe ".geojson_to_placekeys" do
    it "finds placekeys within a GeoJSON polygon" do
      polygon = instance_double("RGeo::Cartesian::Polygon")
      geojson = { "type" => "Polygon", "coordinates" => [[[-122.4428, 37.7370], [-122.4430, 37.7374]]] }
      
      allow(RGeo::GeoJSON).to receive(:decode).and_return(polygon)
      allow(described_class).to receive(:polygon_to_placekeys).and_return({
        interior: ["@5vg-82n-kzz"],
        boundary: ["@5vg-82n-qqq"]
      })
      
      result = described_class.geojson_to_placekeys(geojson)
      
      expect(result).to be_a(Hash)
      expect(result).to have_key(:interior)
      expect(result).to have_key(:boundary)
    end
  end
end