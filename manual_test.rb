#!/usr/bin/env ruby

require_relative 'lib/placekey_rails/constants'

module PlacekeyRails
  # Create a minimal fake H3Adapter module to satisfy dependencies
  module H3Adapter
    def self.string_to_h3(h3_string)
      123456789 # Dummy value
    end

    def self.h3_to_string(h3_index)
      "8a2830828767fff" # Dummy value
    end

    def self.is_valid_cell(h3_index)
      true # Always valid for testing
    end

    def self.stringToH3(h3_string)
      string_to_h3(h3_string)
    end
  end
end

# Load the validator directly
require_relative 'lib/placekey_rails/validator'

# Now test the normalize_placekey_format method
puts "Testing normalize_placekey_format method"
puts "========================================"

test_cases = [
  [ "@5vg-82n-kzz", "@5vg-82n-kzz", "Valid @where format" ],
  [ "23b@5vg-82n-kzz", "@5vg-82n-kzz", "Numeric prefix format" ],
  [ "223227@5vg-82n-kzz", "223-227@5vg-82n-kzz", "what part needing dash (6 chars)" ],
  [ "223@5vg-82n-kzz", "223-@5vg-82n-kzz", "what part needing dash (3 chars)" ]
]

failures = 0
test_cases.each_with_index do |(input, expected, description), index|
  actual = PlacekeyRails::Validator.normalize_placekey_format(input)

  result = actual == expected ? "PASS" : "FAIL"
  puts "Test #{index + 1}: #{description}"
  puts "  Input: #{input}"
  puts "  Expected: #{expected}"
  puts "  Actual: #{actual}"
  puts "  Result: #{result}"
  puts ""

  failures += 1 if actual != expected
end

puts "Summary: #{test_cases.size - failures}/#{test_cases.size} tests passed"
exit(failures == 0 ? 0 : 1)
