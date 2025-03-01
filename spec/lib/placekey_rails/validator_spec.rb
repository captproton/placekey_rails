require 'rails_helper'

RSpec.describe PlacekeyRails::Validator do
  # First, create a module double to mock the real modules
  let(:h3_adapter_mock) { Module.new }
  let(:converter_mock) { Module.new }

  before do
    # Mock the H3Adapter
    stub_const("PlacekeyRails::H3Adapter", h3_adapter_mock)
    allow(h3_adapter_mock).to receive(:is_valid_cell).and_return(true)
    allow(h3_adapter_mock).to receive(:string_to_h3).and_return(123456789)
    
    # Mock the Converter
    stub_const("PlacekeyRails::Converter", converter_mock)
    allow(converter_mock).to receive(:placekey_to_h3).and_return("8a2830828767fff")
    allow(converter_mock).to receive(:placekey_to_h3_int).and_return(123456789)
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
      allow(h3_adapter_mock).to receive(:is_valid_cell).and_return(false)
      result = described_class.where_part_is_valid("5vg-7gq-tvz")
      expect(result).to be false
    end

    it "handles exceptions during conversion" do
      allow(converter_mock).to receive(:placekey_to_h3).and_raise(StandardError)
      result = described_class.where_part_is_valid("5vg-7gq-tvz")
      expect(result).to be false
    end

    context "when conversion fails" do
      before do
        allow(converter_mock).to receive(:placekey_to_h3).and_raise(StandardError)
      end

      it "returns false" do
        result = described_class.where_part_is_valid("5vg-7gq-tvz")
        expect(result).to be false
      end
    end

    it "handles H3 validation exceptions" do
      allow(h3_adapter_mock).to receive(:is_valid_cell).and_raise(StandardError)
      result = described_class.where_part_is_valid("5vg-7gq-tvz")
      expect(result).to be false
    end
  end
end
