#!/usr/bin/env ruby
# This is a super simple test to check if the normalize_placekey_format function works

# Load the validator module
load File.expand_path('lib/placekey_rails/validator.rb')

module PlacekeyRails
  module Converter
    def self.placekey_to_h3(placekey)
      "8a2830828767fff" # Dummy value for testing
    end
  end
  
  module H3Adapter
    def self.string_to_h3(h3_string)
      123456789 # Dummy value for testing
    end
    
    def self.is_valid_cell(h3_index)
      true # Always valid for testing
    end
  end
end

# Test cases
test_cases = [
  ["@5vg-82n-kzz", "@5vg-82n-kzz", "Valid @where format"],
  ["23b@5vg-82n-kzz", "@5vg-82n-kzz", "Numeric prefix format"],
  # These are the two failing cases:
  ["223227@5vg-82n-kzz", "223-227@5vg-82n-kzz", "what part needing dash (6 chars)"],
  ["223@5vg-82n-kzz", "223-@5vg-82n-kzz", "what part needing dash (3 chars)"]
]

# Run the tests
test_cases.each do |input, expected, description|
  actual = PlacekeyRails::Validator.normalize_placekey_format(input)
  result = actual == expected ? "PASS" : "FAIL"
  puts "Test: #{description}"
  puts "  Input: #{input.inspect}"
  puts "  Expected: #{expected.inspect}"
  puts "  Actual: #{actual.inspect}"
  puts "  Result: #{result}"
end
