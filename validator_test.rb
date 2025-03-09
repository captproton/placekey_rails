
# Simple test script for the validator module
require 'rubygems'
require 'bundler/setup'
require 'h3'

# Load only the validator module and its dependencies
require_relative 'lib/placekey_rails/constants'
require_relative 'lib/placekey_rails/h3_adapter'
require_relative 'lib/placekey_rails/converter'
require_relative 'lib/placekey_rails/validator'

# Ensure modules are defined
module PlacekeyRails; end

# Run a simple test
puts "Testing PlacekeyRails::Validator.normalize_placekey_format"

# Test case 1: Basic @where format
placekey = "@5vg-82n-kzz"
result = PlacekeyRails::Validator.normalize_placekey_format(placekey)
puts "Test 1: #{result == placekey ? 'PASS' : 'FAIL'} - Expected: #{placekey}, Got: #{result}"

# Test case 2: Numeric prefix
placekey = "23b@5vg-82n-kzz"
expected = "@5vg-82n-kzz"
result = PlacekeyRails::Validator.normalize_placekey_format(placekey)
puts "Test 2: #{result == expected ? 'PASS' : 'FAIL'} - Expected: #{expected}, Got: #{result}"

# Test case 3: Complex numeric prefix
placekey = "23456@5vg-82n-kzz"
expected = "@5vg-82n-kzz"
result = PlacekeyRails::Validator.normalize_placekey_format(placekey)
puts "Test 3: #{result == expected ? 'PASS' : 'FAIL'} - Expected: #{expected}, Got: #{result}"

# Test case 4: What part with 6 characters
placekey = "223227@5vg-82n-kzz"
expected = "223-227@5vg-82n-kzz"
result = PlacekeyRails::Validator.normalize_placekey_format(placekey)
puts "Test 4: #{result == expected ? 'PASS' : 'FAIL'} - Expected: #{expected}, Got: #{result}"

# Test case 5: What part with 3 characters
placekey = "223@5vg-82n-kzz"
expected = "223-@5vg-82n-kzz"
result = PlacekeyRails::Validator.normalize_placekey_format(placekey)
puts "Test 5: #{result == expected ? 'PASS' : 'FAIL'} - Expected: #{expected}, Got: #{result}"

puts "All tests complete!"
