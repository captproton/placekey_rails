require 'spec_helper'

# This is a unit test that does not require database connection
# We're testing the module methods directly rather than through ActiveRecord
RSpec.describe PlacekeyRails::Concerns::Placekeyable do
  # Create a test class that includes methods from the concern
  let(:test_class) do
    Class.new do
      # Storage for attributes
      attr_reader :attributes

      def initialize
        @attributes = {}
      end

      # Mimic ActiveRecord's attribute writer
      def write_attribute(name, value)
        @attributes[name.to_s] = value
      end

      # Mimic ActiveRecord's attribute reader
      def [](name)
        @attributes[name.to_s]
      end

      # Add the setter we're testing
      def placekey=(value)
        normalized_value = PlacekeyRails::Validator.normalize_placekey_format(value)
        write_attribute(:placekey, normalized_value)
      end

      # Add a reader method
      def placekey
        @attributes["placekey"]
      end
    end
  end

  let(:test_instance) { test_class.new }

  describe "#placekey=" do
    it "normalizes placekeys when assigned" do
      test_instance.placekey = "23b@5vg-82n-kzz"
      expect(test_instance.placekey).to eq("@5vg-82n-kzz")
    end

    it "handles nil values" do
      test_instance.placekey = nil
      expect(test_instance.placekey).to be_nil
    end

    it "handles empty strings" do
      test_instance.placekey = ""
      expect(test_instance.placekey).to eq("")
    end

    it "keeps valid placekeys unchanged" do
      valid_placekey = "@5vg-82n-kzz"
      test_instance.placekey = valid_placekey
      expect(test_instance.placekey).to eq(valid_placekey)
    end

    it "formats what@where keys correctly" do
      test_instance.placekey = "223227@5vg-82n-kzz"
      expect(test_instance.placekey).to eq("223-227@5vg-82n-kzz")
    end
  end
end
