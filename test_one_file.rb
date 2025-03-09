#!/usr/bin/env ruby

# Load all necessary components
require_relative 'lib/placekey_rails/constants'
require_relative 'lib/placekey_rails/converter'
require_relative 'lib/placekey_rails/h3_adapter'
require_relative 'lib/placekey_rails/validator'

# Test each failure case
input1 = "223227@5vg-82n-kzz"
expected1 = "223-227@5vg-82n-kzz"
actual1 = PlacekeyRails::Validator.normalize_placekey_format(input1)

input2 = "223@5vg-82n-kzz"
expected2 = "223-@5vg-82n-kzz"
actual2 = PlacekeyRails::Validator.normalize_placekey_format(input2)

# Print results
puts "Test 1: Format 6-char what part"
puts "Input: #{input1}"
puts "Expected: #{expected1}"
puts "Actual: #{actual1}"
puts "Result: #{actual1 == expected1 ? 'PASS' : 'FAIL'}"
puts

puts "Test 2: Format 3-char what part"
puts "Input: #{input2}"
puts "Expected: #{expected2}"
puts "Actual: #{actual2}"
puts "Result: #{actual2 == expected2 ? 'PASS' : 'FAIL'}"
