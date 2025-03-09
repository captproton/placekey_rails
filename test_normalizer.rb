#!/usr/bin/env ruby

# Mock the necessary dependencies
module PlacekeyRails
  # Constants for Placekey encoding
  RESOLUTION = 10
  BASE_RESOLUTION = 12
  ALPHABET = "23456789bcdfghjkmnpqrstvwxyz".freeze
  ALPHABET_LENGTH = ALPHABET.length
  CODE_LENGTH = 9
  TUPLE_LENGTH = 3
  PADDING_CHAR = "a"
  REPLACEMENT_CHARS = "eu"
  REPLACEMENT_MAP = [
    [ "prn", "pre" ],
    [ "f4nny", "f4nne" ],
    [ "tw4t", "tw4e" ],
    [ "ngr", "ngu" ],
    [ "dck", "dce" ],
    [ "vjn", "vju" ],
    [ "fck", "fce" ],
    [ "pns", "pne" ],
    [ "sht", "she" ],
    [ "kkk", "kke" ],
    [ "fgt", "fgu" ],
    [ "dyk", "dye" ],
    [ "bch", "bce" ]
  ].freeze

  module H3Adapter
    def self.string_to_h3(h3_string)
      123456789 # Dummy value for testing
    end

    def self.is_valid_cell(h3_index)
      true # Always valid for testing
    end
  end

  module Converter
    def self.placekey_to_h3(placekey)
      "8a2830828767fff" # Dummy value for testing
    end
  end
end

# Load the validator module
require_relative 'lib/placekey_rails/validator'

# Test cases
test_cases = [
  [ "@5vg-82n-kzz", "@5vg-82n-kzz", "Valid @where format" ],
  [ "23b@5vg-82n-kzz", "@5vg-82n-kzz", "Numeric prefix format" ],
  [ "223227@5vg-82n-kzz", "223-227@5vg-82n-kzz", "What part needing dash (6 chars)" ],
  [ "223@5vg-82n-kzz", "223-@5vg-82n-kzz", "What part needing dash (3 chars)" ],
  [ "5vg-82n-kzz", "@5vg-82n-kzz", "Where part only" ],
  [ "223-227@5vg-82n-kzz", "223-227@5vg-82n-kzz", "Already formatted what@where" ]
]

# Run the tests
puts "Testing PlacekeyRails::Validator.normalize_placekey_format"
puts "========================================================"

failures = 0
test_cases.each_with_index do |(input, expected, description), index|
  actual = PlacekeyRails::Validator.normalize_placekey_format(input)

  result = actual == expected ? "PASS" : "FAIL"
  puts "Test #{index + 1}: #{description}"
  puts "  Input: #{input.inspect}"
  puts "  Expected: #{expected.inspect}"
  puts "  Actual: #{actual.inspect}"
  puts "  Result: #{result}"
  puts ""

  failures += 1 if actual != expected
end

puts "Summary: #{test_cases.size - failures}/#{test_cases.size} tests passed"
exit(failures == 0 ? 0 : 1)
