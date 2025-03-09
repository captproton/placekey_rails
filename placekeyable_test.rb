
# Simple test script for the placekeyable concern
require 'rubygems'
require 'bundler/setup'
require 'h3'

# Load only the validator module and its dependencies
require_relative 'lib/placekey_rails/constants'
require_relative 'lib/placekey_rails/h3_adapter'
require_relative 'lib/placekey_rails/converter'
require_relative 'lib/placekey_rails/validator'

# Create a test class with the placekey= method
class TestClass
  # Storage for attributes
  attr_reader :attributes
  
  def initialize
    @attributes = {}
  end
  
  # Mimic ActiveRecord's attribute writer
  def write_attribute(name, value)
    @attributes[name.to_s] = value
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

# Run a simple test
puts "Testing Placekeyable#placekey="

# Create test instance
test_instance = TestClass.new

# Test case 1: Numeric prefix
test_instance.placekey = "23b@5vg-82n-kzz"
expected = "@5vg-82n-kzz"
result = test_instance.placekey
puts "Test 1: #{result == expected ? 'PASS' : 'FAIL'} - Expected: #{expected}, Got: #{result}"

# Test case 2: Valid placekey
placekey = "@5vg-82n-kzz"
test_instance.placekey = placekey
result = test_instance.placekey
puts "Test 2: #{result == placekey ? 'PASS' : 'FAIL'} - Expected: #{placekey}, Got: #{result}"

# Test case 3: Nil value
test_instance.placekey = nil
result = test_instance.placekey
puts "Test 3: #{result.nil? ? 'PASS' : 'FAIL'} - Expected: nil, Got: #{result}"

# Test case 4: What part with 6 characters
test_instance.placekey = "223227@5vg-82n-kzz"
expected = "223-227@5vg-82n-kzz"
result = test_instance.placekey
puts "Test 4: #{result == expected ? 'PASS' : 'FAIL'} - Expected: #{expected}, Got: #{result}"

# Test case 5: What part with 3 characters
test_instance.placekey = "223@5vg-82n-kzz"
expected = "223-@5vg-82n-kzz"
result = test_instance.placekey
puts "Test 5: #{result == expected ? 'PASS' : 'FAIL'} - Expected: #{expected}, Got: #{result}"

puts "All tests complete!"
