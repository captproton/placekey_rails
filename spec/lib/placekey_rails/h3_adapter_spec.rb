require 'rails_helper'

RSpec.describe PlacekeyRails::H3Adapter do
  # These tests verify that our adapter correctly maps H3 gem methods
  # to the equivalent methods in the original Placekey Python library.
  
  describe ".latLngToCell" do
    it "calls H3::Indexing.geo_to_h3" do
      expect(H3::Indexing).to receive(:geo_to_h3).with([37.7371, -122.44283], 10)
      described_class.latLngToCell(37.7371, -122.44283, 10)
    end
  end
  
  describe ".cellToLatLng" do
    it "calls H3::Indexing.h3_to_geo" do
      expect(H3::Indexing).to receive(:h3_to_geo).with(123456789)
      described_class.cellToLatLng(123456789)
    end
  end
  
  describe ".stringToH3" do
    it "calls H3::Indexing.string_to_h3" do
      expect(H3::Indexing).to receive(:string_to_h3).with("8a2830828767fff")
      described_class.stringToH3("8a2830828767fff")
    end
  end
  
  describe ".h3ToString" do
    it "calls H3::Indexing.h3_to_string" do
      expect(H3::Indexing).to receive(:h3_to_string).with(123456789)
      described_class.h3ToString(123456789)
    end
  end
  
  describe ".isValidCell" do
    it "calls H3::Inspection.h3_is_valid" do
      expect(H3::Inspection).to receive(:h3_is_valid).with(123456789)
      described_class.isValidCell(123456789)
    end
  end
  
  describe ".gridDisk" do
    it "calls H3::Hierarchy.hex_range" do
      expect(H3::Hierarchy).to receive(:hex_range).with(123456789, 1)
      described_class.gridDisk(123456789, 1)
    end
  end
  
  describe ".cellToBoundary" do
    it "calls H3::Indexing.h3_to_geo_boundary" do
      expect(H3::Indexing).to receive(:h3_to_geo_boundary).with(123456789)
      described_class.cellToBoundary(123456789)
    end
  end
  
  describe ".polyfill" do
    it "calls H3::Regions.polyfill with appropriate arguments" do
      # Mock a polygon with exterior ring
      polygon = double('Polygon')
      exterior_ring = double('LineString')
      point1 = double('Point', x: -122.4428, y: 37.7370)
      point2 = double('Point', x: -122.4430, y: 37.7374)
      points = [point1, point2]
      
      allow(polygon).to receive(:exterior_ring).and_return(exterior_ring)
      allow(exterior_ring).to receive(:points).and_return(points)
      allow(polygon).to receive(:interior_rings).and_return([])
      
      resolution = 10
      
      # The expected conversion of polygon points to [lat, lng] format
      expected_coords = [[37.7370, -122.4428], [37.7374, -122.4430]]
      
      expect(H3::Regions).to receive(:polyfill).with(expected_coords, [], resolution)
      described_class.polyfill(polygon, resolution)
    end
    
    it "handles simple polygon formats" do
      # Mock a simple polygon without proper methods
      polygon = double('SimplePolygon')
      resolution = 10
      
      # For simple polygon formats, we expect a fallback behavior
      expect(H3::Regions).to receive(:polyfill).with(polygon, [], resolution)
      described_class.polyfill(polygon, resolution)
    end
  end
end