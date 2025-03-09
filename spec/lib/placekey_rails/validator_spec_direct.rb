
# Test the validator directly
require 'h3'

# Load dependencies directly
require_relative '../../../lib/placekey_rails/constants'
require_relative '../../../lib/placekey_rails/h3_adapter'
require_relative '../../../lib/placekey_rails/converter'

# Load the validator we're testing
require_relative '../../../lib/placekey_rails/validator'

# Create test module for constants
module PlacekeyRails
end

describe PlacekeyRails::Validator do
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
  end
end
