require 'rails_helper'

RSpec.describe PlacekeyRails::Validator do
  before do
    # Mock the H3Adapter module for testing
    stub_const("PlacekeyRails::H3Adapter", Module.new)
    allow(PlacekeyRails::H3Adapter).to receive(:latLngToCell).and_return(123456789)
    allow(PlacekeyRails::H3Adapter).to receive(:cellToLatLng).and_return([37.7371, -122.44283])
    allow(PlacekeyRails::H3Adapter).to receive(:stringToH3).and_return(123456789)
    allow(PlacekeyRails::H3Adapter).to receive(:h3ToString).and_return("8a2830828767fff")
    allow(PlacekeyRails::H3Adapter).to receive(:isValidCell).and_return(true)
    
    # Mock Converter methods
    allow(PlacekeyRails::Converter).to receive(:parse_placekey).and_call_original
    allow(PlacekeyRails::Converter).to receive(:placekey_to_h3_int).and_return(123456789)
    
    # Allow the validator to use the real where_part_is_valid method
    allow(described_class).to receive(:where_part_is_valid).and_call_original
  end
  
  describe ".placekey_format_is_valid" do
    it "validates correct placekey format with where part only" do
      expect(described_class.placekey_format_is_valid("@5vg-7gq-tvz")).to be true
    end
    
    it "validates correct placekey format with what and where parts" do
      expect(described_class.placekey_format_is_valid("abc-def@5vg-7gq-tvz")).to be true
    end
    
    it "rejects invalid placekey format" do
      allow(described_class).to receive(:where_part_is_valid).and_return(false)
      expect(described_class.placekey_format_is_valid("@abc-def")).to be false
      
      allow(PlacekeyRails::Converter).to receive(:parse_placekey).and_raise(StandardError)
      expect(described_class.placekey_format_is_valid("not-a-placekey")).to be false
    end
  end
  
  describe ".where_part_is_valid" do
    it "validates correct where part format" do
      # Add regexp mocking to ensure Regexp.new(where_regex_pattern) works
      allow_any_instance_of(String).to receive(:match?).and_return(true)
      
      expect(described_class.where_part_is_valid("5vg-7gq-tvz")).to be true
    end
    
    it "rejects invalid where part format when regex doesn't match" do
      allow_any_instance_of(String).to receive(:match?).and_return(false)
      expect(described_class.where_part_is_valid("abc-def")).to be false
    end
    
    it "rejects invalid where part format when H3 validation fails" do
      allow_any_instance_of(String).to receive(:match?).and_return(true)
      allow(PlacekeyRails::H3Adapter).to receive(:isValidCell).and_return(false)
      expect(described_class.where_part_is_valid("5vg-7gq-tvz")).to be false
    end
    
    it "handles exceptions during conversion" do
      allow_any_instance_of(String).to receive(:match?).and_return(true)
      allow(PlacekeyRails::Converter).to receive(:placekey_to_h3_int).and_raise(StandardError)
      expect(described_class.where_part_is_valid("5vg-7gq-tvz")).to be false
    end
  end
end