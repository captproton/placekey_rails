require 'spec_helper'

RSpec.describe PlacekeyRails::Validator do
  describe ".normalize_placekey_format" do
    it "keeps valid @where placekeys unchanged" do
      placekey = "@5vg-82n-kzz"
      expect(described_class.normalize_placekey_format(placekey)).to eq(placekey)
    end
    
    it "removes numeric prefixes from placekeys" do
      placekey = "23b@5vg-82n-kzz"
      expect(described_class.normalize_placekey_format(placekey)).to eq("@5vg-82n-kzz")
    end
    
    it "keeps valid what@where format placekeys unchanged" do
      placekey = "223-227@5vg-82n-kzz"
      expect(described_class.normalize_placekey_format(placekey)).to eq(placekey)
    end
    
    it "adds dash to what part when missing" do
      placekey = "223227@5vg-82n-kzz"
      expect(described_class.normalize_placekey_format(placekey)).to eq("223-227@5vg-82n-kzz")
    end
    
    it "adds dash to single what part" do
      placekey = "223@5vg-82n-kzz"
      expect(described_class.normalize_placekey_format(placekey)).to eq("223-@5vg-82n-kzz")
    end
    
    it "returns nil for nil input" do
      expect(described_class.normalize_placekey_format(nil)).to be_nil
    end
  end
end
