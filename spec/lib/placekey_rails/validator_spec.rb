require 'spec_helper'

RSpec.describe PlacekeyRails::Validator do
  describe ".normalize_placekey_format" do
    it "keeps valid @where placekeys unchanged" do
      placekey = "@5vg-82n-kzz"
      expect(described_class.normalize_placekey_format(placekey)).to eq(placekey)
    end
    
    it "removes simple numeric prefixes from placekeys" do
      placekey = "23b@5vg-82n-kzz"
      expect(described_class.normalize_placekey_format(placekey)).to eq("@5vg-82n-kzz")
    end
    
    it "handles complex numeric prefixes" do
      placekey = "23456@5vg-82n-kzz"
      expect(described_class.normalize_placekey_format(placekey)).to eq("@5vg-82n-kzz")
    end
    
    it "keeps valid what@where format placekeys unchanged" do
      placekey = "223-227@5vg-82n-kzz"
      expect(described_class.normalize_placekey_format(placekey)).to eq(placekey)
    end
    
    it "adds dash to what part when it has 6 characters" do
      placekey = "223227@5vg-82n-kzz"
      expect(described_class.normalize_placekey_format(placekey)).to eq("223-227@5vg-82n-kzz")
    end
    
    it "adds dash to single what part with 3 characters" do
      placekey = "223@5vg-82n-kzz"
      expect(described_class.normalize_placekey_format(placekey)).to eq("223-@5vg-82n-kzz")
    end
    
    it "adds @ symbol to where-only keys" do
      placekey = "5vg-82n-kzz"
      expect(described_class.normalize_placekey_format(placekey)).to eq("@5vg-82n-kzz")
    end
    
    it "returns nil for nil input" do
      expect(described_class.normalize_placekey_format(nil)).to be_nil
    end
    
    it "returns original placekey for unrecognized formats" do
      placekey = "invalid-format"
      expect(described_class.normalize_placekey_format(placekey)).to eq(placekey)
    end
    
    it "returns empty string for empty input" do
      expect(described_class.normalize_placekey_format("")).to eq("")
    end
    
    it "handles real API response examples" do
      # Test with real examples from API responses
      examples = {
        "12a@5vg-849-gp9" => "@5vg-849-gp9",
        "23456789@5vg-82n-kzz" => "@5vg-82n-kzz",
        "123abc@5vg-82n-kzz" => "@5vg-82n-kzz"
      }
      
      examples.each do |input, expected|
        expect(described_class.normalize_placekey_format(input)).to eq(expected)
      end
    end
  end
  
  describe ".placekey_format_is_valid_normalized" do
    # Mock the placekey_format_is_valid method to isolate this test
    before do
      allow(described_class).to receive(:placekey_format_is_valid).and_call_original
    end
    
    it "validates standard format placekeys" do
      placekey = "@5vg-82n-kzz"
      expect(described_class.placekey_format_is_valid_normalized(placekey)).to eq(
        described_class.placekey_format_is_valid(placekey)
      )
    end
    
    it "validates placekeys after normalizing them" do
      placekey = "23b@5vg-849-gp9"
      normalized = "@5vg-849-gp9"
      
      # It should normalize and then validate
      expect(described_class).to receive(:normalize_placekey_format).with(placekey).and_return(normalized)
      expect(described_class).to receive(:placekey_format_is_valid).with(normalized)
      
      described_class.placekey_format_is_valid_normalized(placekey)
    end
    
    it "rejects invalid placekeys even after normalization" do
      invalid_placekey = "invalid-format"
      
      # The original validation should return false
      allow(described_class).to receive(:placekey_format_is_valid).with(invalid_placekey).and_return(false)
      
      expect(described_class.placekey_format_is_valid_normalized(invalid_placekey)).to be false
    end
  end
  
  # Test the existing placekey_format_is_valid method
  describe ".placekey_format_is_valid" do
    it "validates @where format" do
      expect(described_class.placekey_format_is_valid("@5vg-82n-kzz")).to be true
    end
    
    it "validates what@where format" do
      expect(described_class.placekey_format_is_valid("223-227@5vg-82n-kzz")).to be true
    end
    
    it "rejects invalid formats" do
      expect(described_class.placekey_format_is_valid("invalid-format")).to be false
    end
    
    it "rejects nil input" do
      expect(described_class.placekey_format_is_valid(nil)).to be false
    end
    
    it "rejects empty string" do
      expect(described_class.placekey_format_is_valid("")).to be false
    end
  end
end