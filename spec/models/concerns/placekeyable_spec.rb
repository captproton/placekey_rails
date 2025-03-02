require 'rails_helper'

RSpec.describe PlacekeyRails::Concerns::Placekeyable, type: :concern do
  # Use the Location model from the dummy app for testing
  let(:location_class) { Location }
  
  # Valid test data
  let(:valid_latitude) { 37.7371 }
  let(:valid_longitude) { -122.44283 }
  let(:valid_placekey) { "@5vg-82n-kzz" }
  
  # Invalid test data
  let(:invalid_placekey) { "invalid-format" }
  
  describe "validations" do
    it "validates a correctly formatted placekey" do
      location = location_class.new(placekey: valid_placekey)
      expect(location).to be_valid
    end
    
    it "invalidates an incorrectly formatted placekey" do
      location = location_class.new(placekey: invalid_placekey)
      expect(location).not_to be_valid
      expect(location.errors[:placekey]).to include("is not a valid Placekey format")
    end
    
    it "allows a blank placekey" do
      location = location_class.new(placekey: nil)
      expect(location).to be_valid
    end
  end
  
  describe "automatic placekey generation" do
    it "generates a placekey from coordinates before validation" do
      location = location_class.new(latitude: valid_latitude, longitude: valid_longitude)
      location.valid?
      expect(location.placekey).to be_present
      expect(PlacekeyRails.placekey_format_is_valid(location.placekey)).to be true
    end
    
    it "does not generate a placekey if coordinates are missing" do
      location = location_class.new(name: "Test Location")
      location.valid?
      expect(location.placekey).to be_nil
    end
    
    it "does not overwrite an existing placekey" do
      location = location_class.new(
        latitude: valid_latitude,
        longitude: valid_longitude,
        placekey: valid_placekey
      )
      location.valid?
      expect(location.placekey).to eq(valid_placekey)
    end
  end
  
  describe "instance methods" do
    let(:location) { location_class.create(placekey: valid_placekey) }
    let(:other_location) { location_class.create(placekey: "@5vg-7gq-tvz") }
    
    context "#placekey_to_geo" do
      it "converts placekey to coordinates" do
        lat, lng = location.placekey_to_geo
        expect(lat).to be_within(0.001).of(valid_latitude)
        expect(lng).to be_within(0.001).of(valid_longitude)
      end
      
      it "returns nil if placekey is blank" do
        location = location_class.new
        expect(location.placekey_to_geo).to be_nil
      end
    end
    
    context "#placekey_to_h3" do
      it "converts placekey to H3 index" do
        h3_index = location.placekey_to_h3
        expect(h3_index).to be_a(String)
        expect(h3_index).to match(/^[0-9a-f]+$/)
      end
      
      it "returns nil if placekey is blank" do
        location = location_class.new
        expect(location.placekey_to_h3).to be_nil
      end
    end
    
    context "#placekey_boundary" do
      it "returns boundary coordinates" do
        boundary = location.placekey_boundary
        expect(boundary).to be_an(Array)
        expect(boundary.size).to eq(6) # Hexagon has 6 sides
        expect(boundary.first).to be_an(Array)
        expect(boundary.first.size).to eq(2) # [lat, lng]
      end
      
      it "returns GeoJSON format when requested" do
        boundary = location.placekey_boundary(true)
        expect(boundary).to be_an(Array)
        expect(boundary.size).to eq(6) # Hexagon has 6 sides
        expect(boundary.first).to be_an(Array)
        expect(boundary.first.size).to eq(2) # [lng, lat] in GeoJSON format
      end
      
      it "returns nil if placekey is blank" do
        location = location_class.new
        expect(location.placekey_boundary).to be_nil
      end
    end
    
    context "#placekey_to_geojson" do
      it "converts placekey to GeoJSON" do
        geojson = location.placekey_to_geojson
        expect(geojson).to be_a(Hash)
        expect(geojson["type"]).to eq("Feature")
        expect(geojson["geometry"]["type"]).to eq("Polygon")
      end
      
      it "returns nil if placekey is blank" do
        location = location_class.new
        expect(location.placekey_to_geojson).to be_nil
      end
    end
    
    context "#neighboring_placekeys" do
      it "finds neighboring placekeys" do
        neighbors = location.neighboring_placekeys
        expect(neighbors).to be_a(Set)
        expect(neighbors.size).to be >= 1 # At least the original placekey
      end
      
      it "accepts a distance parameter" do
        neighbors = location.neighboring_placekeys(2)
        expect(neighbors.size).to be > location.neighboring_placekeys(1).size
      end
      
      it "returns empty array if placekey is blank" do
        location = location_class.new
        expect(location.neighboring_placekeys).to eq([])
      end
    end
    
    context "#distance_to" do
      it "calculates distance to another placekey" do
        distance = location.distance_to(other_location.placekey)
        expect(distance).to be_a(Numeric)
        expect(distance).to be > 0
      end
      
      it "calculates distance to another placekeyable object" do
        distance = location.distance_to(other_location)
        expect(distance).to be_a(Numeric)
        expect(distance).to be > 0
      end
      
      it "returns nil if placekey is blank" do
        location = location_class.new
        expect(location.distance_to(other_location)).to be_nil
      end
      
      it "returns nil if other placekey is invalid" do
        expect(location.distance_to("invalid")).to be_nil
      end
    end
  end
  
  describe "class methods" do
    before do
      # Create test data
      location_class.create(latitude: 37.7371, longitude: -122.44283, name: "Location 1")
      location_class.create(latitude: 37.7373, longitude: -122.4430, name: "Location 2")
      location_class.create(latitude: 38.5816, longitude: -121.4944, name: "Location 3") # Sacramento (far away)
    end
    
    context ".within_distance" do
      it "finds locations within the specified distance" do
        # Get placekey for a known location
        origin_placekey = PlacekeyRails.geo_to_placekey(37.7371, -122.44283)
        
        # Find locations within 500 meters
        nearby = location_class.within_distance(origin_placekey, 500)
        expect(nearby.size).to eq(2) # Should find 2 nearby locations
        
        # Locations should be instances of Location
        expect(nearby.first).to be_a(location_class)
      end
      
      it "excludes locations outside the specified distance" do
        # Get placekey for a known location
        origin_placekey = PlacekeyRails.geo_to_placekey(37.7371, -122.44283)
        
        # Find locations within 500 meters
        nearby = location_class.within_distance(origin_placekey, 500)
        
        # Sacramento location should not be included
        sacramento = location_class.find_by(name: "Location 3")
        expect(nearby).not_to include(sacramento)
      end
    end
    
    context ".near_coordinates" do
      it "finds locations near the specified coordinates" do
        # Find locations within 500 meters of coordinates
        nearby = location_class.near_coordinates(37.7371, -122.44283, 500)
        expect(nearby.size).to eq(2) # Should find 2 nearby locations
        
        # Sacramento location should not be included
        sacramento = location_class.find_by(name: "Location 3")
        expect(nearby).not_to include(sacramento)
      end
    end
    
    # Testing batch_geocode_addresses requires a mocked API client
    # This would be tested separately
  end
end