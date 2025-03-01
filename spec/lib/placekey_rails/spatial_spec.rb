require 'rails_helper'
require 'rgeo'
require 'rgeo/geo_json'
require 'set'

RSpec.describe PlacekeyRails::Spatial do
  let(:h3_adapter) { class_double(PlacekeyRails::H3Adapter).as_stubbed_const }
  let(:rgeo_factory) { instance_double("RGeo::Cartesian::Factory") }
  let(:polygon) { instance_double("RGeo::Cartesian::Polygon") }
  let(:point) { instance_double("RGeo::Cartesian::Point") }
  let(:linear_ring) { instance_double("RGeo::Cartesian::LinearRing") }

  # Update polygon coordinates to have exactly 6 points for hexagon
  let(:hex_coords) do
    [
      [37.7371, -122.44283],
      [37.7373, -122.44284],
      [37.7375, -122.44283],
      [37.7375, -122.44281],
      [37.7373, -122.44280],
      [37.7371, -122.44281]
    ]
  end

  before do
    # RGeo factory setup
    allow(RGeo::Cartesian).to receive(:factory) { rgeo_factory }
    allow(rgeo_factory).to receive(:point) { point }
    allow(rgeo_factory).to receive(:linear_ring) { linear_ring }
    allow(rgeo_factory).to receive(:polygon).with(linear_ring) { polygon }
    allow(rgeo_factory).to receive(:parse_wkt) { polygon }

    # Polygon behavior
    allow(polygon).to receive(:buffer) { polygon }
    allow(polygon).to receive(:contains?) { true }
    allow(polygon).to receive(:intersects?) { true }
    allow(polygon).to receive(:as_text) { "POLYGON((-122.4428 37.7370, -122.4430 37.7374, -122.4428 37.7378))" }
    allow(polygon).to receive(:coordinates) { hex_coords }

    # Existing H3Adapter stubs
    allow(h3_adapter).to receive(:lat_lng_to_cell) { 123456789 }
    allow(h3_adapter).to receive(:cell_to_lat_lng) { [37.7371, -122.44283] }
    allow(h3_adapter).to receive(:string_to_h3) { 123456789 }
    allow(h3_adapter).to receive(:h3_to_string) { "8a2830828767fff" }
    allow(h3_adapter).to receive(:grid_disk) { [123456789, 123456790, 123456791] }
    allow(h3_adapter).to receive(:cell_to_boundary) { hex_coords }
    allow(h3_adapter).to receive(:polyfill) { [123456789, 123456790] }

    # Mock PlacekeyRails::Converter methods
    allow(PlacekeyRails::Converter).to receive(:placekey_to_h3_int) { 123456789 }
    allow(PlacekeyRails::Converter).to receive(:h3_int_to_placekey) { "@5vg-82n-kzz" }

    # Add RGeo requirements
    allow(RGeo::GeoJSON).to receive(:decode) { polygon }
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
      placekey1 = "@5vg-7gq-tvz"
      placekey2 = "@5vg-82n-kzz"

      result = described_class.placekey_distance(placekey1, placekey2)
      expect(result).to be_within(0.1).of(0.0)  # Changed from be.within to be_within
    end
  end

  describe ".placekey_to_hex_boundary" do
    it "returns boundary coordinates" do
      placekey = "@5vg-7gq-tvz"
      result = described_class.placekey_to_hex_boundary(placekey)

      expect(result).to be_an(Array)
      expect(result.size).to eq(6)
      expect(result.first).to eq([37.7371, -122.44283])
    end

    it "returns boundary coordinates in GeoJSON format" do
      placekey = "@5vg-7gq-tvz"
      result = described_class.placekey_to_hex_boundary(placekey, geo_json: true)

      expect(result).to be_an(Array)
      expect(result.size).to eq(6)
      expect(result.first).to eq([-122.44283, 37.7371])
    end
  end

  describe ".placekey_to_polygon" do
    it "returns a polygon from placekey" do
      factory = instance_double("RGeo::Cartesian::Factory")
      linear_ring = instance_double("RGeo::Cartesian::LinearRing")
      polygon = instance_double("RGeo::Cartesian::Polygon")
      point = instance_double("RGeo::Cartesian::Point")

      allow(RGeo::Cartesian).to receive(:factory) { factory }
      allow(factory).to receive(:point) { point }
      allow(factory).to receive(:linear_ring) { linear_ring }
      allow(factory).to receive(:polygon) { polygon }

      placekey = "@5vg-7gq-tvz"
      result = described_class.placekey_to_polygon(placekey)

      expect(result).to eq(polygon)
    end
  end

  describe ".placekey_to_wkt" do
    it "converts placekey to WKT" do
      placekey = "@5vg-7gq-tvz"
      expected_wkt = "POLYGON((-122.4428 37.7370, -122.4430 37.7374, -122.4428 37.7378))"

      result = described_class.placekey_to_wkt(placekey)
      expect(result).to eq(expected_wkt)
    end
  end

  describe ".placekey_to_geojson" do
    let(:geojson) do
      {
        "type" => "Polygon",
        "coordinates" => [[[-122.4428, 37.7370], [-122.4430, 37.7374], [-122.4428, 37.7378]]]
      }
    end

    before do
      allow(RGeo::GeoJSON).to receive(:encode).with(polygon) { geojson }
    end

    it "converts placekey to GeoJSON" do
      placekey = "@5vg-7gq-tvz"
      result = described_class.placekey_to_geojson(placekey)
      expect(result).to eq(geojson)
    end
  end

  describe ".polygon_to_placekeys" do
    it "finds placekeys within a polygon" do
      allow(h3_adapter).to receive(:polyfill) { [123456789, 123456790] }  # Use h3_adapter instead of H3Adapter
      result = described_class.polygon_to_placekeys(polygon)

      expect(result).to be_a(Hash)
      expect(result[:interior]).to eq(["@5vg-82n-kzz"])
      expect(result[:boundary]).to eq([])
    end
  end

  describe ".wkt_to_placekeys" do
    it "finds placekeys within a WKT polygon" do
      wkt = "POLYGON((-122.4428 37.7370, -122.4430 37.7374, -122.4428 37.7378))"
      allow(rgeo_factory).to receive(:parse_wkt).with(wkt) { polygon }

      # Mock a single placekey return
      allow(PlacekeyRails::Converter).to receive(:h3_int_to_placekey).exactly(2).times { "@5vg-82n-kzz" }

      result = described_class.wkt_to_placekeys(wkt)
      expect(result).to be_a(Hash)
      expect(result[:interior]).to eq(["@5vg-82n-kzz"])  # Now expects only one unique value
      expect(result[:boundary]).to eq([])
    end
  end

  describe ".geojson_to_placekeys" do
    let(:geojson) do
      {
        "type" => "Polygon",
        "coordinates" => [[
          [-122.4428, 37.7370],
          [-122.4430, 37.7374],
          [-122.4428, 37.7378],
          [-122.4423, 37.7378],
          [-122.4421, 37.7374],
          [-122.4423, 37.7370],
          [-122.4428, 37.7370]
        ]]
      }
    end

    before do
      allow(RGeo::GeoJSON).to receive(:decode) { polygon }
      allow(described_class).to receive(:polygon_to_placekeys) {
        {
          interior: ["@5vg-82n-kzz"],
          boundary: ["@5vg-82n-qqq"]
        }
      }
    end

    it "finds placekeys within a GeoJSON polygon" do
      result = described_class.geojson_to_placekeys(geojson)
      expect(result).to include(
        interior: ["@5vg-82n-kzz"],
        boundary: ["@5vg-82n-qqq"]
      )
    end
  end
end
