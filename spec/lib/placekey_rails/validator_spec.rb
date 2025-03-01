require 'rails_helper'

RSpec.describe PlacekeyRails::Validator do
  before do
    # Create the mocks as modules with the necessary methods
    h3_adapter = Module.new
    h3_adapter.define_singleton_method(:is_valid_cell) { |_h3_index| true }
    h3_adapter.define_singleton_method(:string_to_h3) { |_h3_string| 123456789 }
    
    converter = Module.new
    converter.define_singleton_method(:placekey_to_h3) { |_placekey| "8a2830828767fff" }
    converter.define_singleton_method(:placekey_to_h3_int) { |_placekey| 123456789 }
    
    # Stub the real constants with our mocks
    stub_const("PlacekeyRails::H3Adapter", h3_adapter)
    stub_const("PlacekeyRails::Converter", converter)
  end

  describe ".placekey_format_is_valid" do
    context "with where part only" do
      it "validates correct placekey format" do
        result = described_class.placekey_format_is_valid("@5vg-7gq-tvz")
        expect(result).to be true
      end
    end

    it "validates correct placekey format with what and where parts" do
      result = described_class.placekey_format_is_valid("222-227@5vg-7gq-tvz")
      expect(result).to be true
    end

    it "rejects invalid placekey format" do
      result = described_class.placekey_format_is_valid("invalid-format")
      expect(result).to be false
    end
  end

  describe ".where_part_is_valid" do
    it "validates correct where part format" do
      result = described_class.where_part_is_valid("5vg-7gq-tvz")
      expect(result).to be true
    end

    it "rejects invalid where part format when regex doesn't match" do
      result = described_class.where_part_is_valid("invalid-format")
      expect(result).to be false
    end

    it "rejects invalid where part format when H3 validation fails" do
      # Create a new mock with different behavior for this specific test
      h3_adapter = Module.new
      h3_adapter.define_singleton_method(:is_valid_cell) { |_h3_index| false }
      h3_adapter.define_singleton_method(:string_to_h3) { |_h3_string| 123456789 }
      stub_const("PlacekeyRails::H3Adapter", h3_adapter)
      
      result = described_class.where_part_is_valid("5vg-7gq-tvz")
      expect(result).to be false
    end

    it "handles exceptions during conversion" do
      # Create a new mock with different behavior for this specific test
      converter = Module.new
      converter.define_singleton_method(:placekey_to_h3) { |_placekey| raise StandardError }
      converter.define_singleton_method(:placekey_to_h3_int) { |_placekey| 123456789 }
      stub_const("PlacekeyRails::Converter", converter)
      
      result = described_class.where_part_is_valid("5vg-7gq-tvz")
      expect(result).to be false
    end

    context "when conversion fails" do
      before do
        # Create a new mock with different behavior for this specific test context
        converter = Module.new
        converter.define_singleton_method(:placekey_to_h3) { |_placekey| raise StandardError }
        converter.define_singleton_method(:placekey_to_h3_int) { |_placekey| 123456789 }
        stub_const("PlacekeyRails::Converter", converter)
      end

      it "returns false" do
        result = described_class.where_part_is_valid("5vg-7gq-tvz")
        expect(result).to be false
      end
    end

    it "handles H3 validation exceptions" do
      # Create a new mock with different behavior for this specific test
      h3_adapter = Module.new
      h3_adapter.define_singleton_method(:is_valid_cell) { |_h3_index| raise StandardError }
      h3_adapter.define_singleton_method(:string_to_h3) { |_h3_string| 123456789 }
      stub_const("PlacekeyRails::H3Adapter", h3_adapter)
      
      result = described_class.where_part_is_valid("5vg-7gq-tvz")
      expect(result).to be false
    end
  end
end
