require 'rails_helper'

RSpec.describe PlacekeyRails::Validator do
  let(:h3_adapter) { class_double(PlacekeyRails::H3Adapter).as_stubbed_const }
  let(:converter) { class_double(PlacekeyRails::Converter).as_stubbed_const }

  before do
    allow(h3_adapter).to receive(:lat_lng_to_cell) { 123456789 }
    allow(h3_adapter).to receive(:string_to_h3) { 123456789 }
    allow(h3_adapter).to receive(:h3_to_string) { "8a2830828767fff" }
    allow(h3_adapter).to receive(:is_valid_cell) { true }
    allow(converter).to receive(:placekey_to_h3_int) { 123456789 }
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
      allow(h3_adapter).to receive(:is_valid_cell) { false }  # Use snake_case
      result = described_class.where_part_is_valid("5vg-7gq-tvz")
      expect(result).to be false
    end

    it "handles exceptions during conversion" do
      allow(h3_adapter).to receive(:string_to_h3).and_raise(StandardError)
      result = described_class.where_part_is_valid("5vg-7gq-tvz")
      expect(result).to be false
    end

    context "when conversion fails" do
      before do
        allow(converter).to receive(:placekey_to_h3_int).and_raise(StandardError)
      end

      it "returns false" do
        result = described_class.where_part_is_valid("5vg-7gq-tvz")
        expect(result).to be false
      end
    end

    it "handles exceptions during conversion" do
      allow(PlacekeyRails::Converter).to receive(:placekey_to_h3_int).and_raise(StandardError)
      result = described_class.where_part_is_valid("5vg-7gq-tvz")
      expect(result).to be false
    end

    it "handles H3 validation exceptions" do
      allow(h3_adapter).to receive(:is_valid_cell).and_raise(StandardError)
      result = described_class.where_part_is_valid("5vg-7gq-tvz")
      expect(result).to be false
    end
  end
end
