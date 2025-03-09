#!/usr/bin/env ruby

require_relative 'lib/placekey_rails/validator'

# Turn on verbose output
$VERBOSE = true

class PlacekeyTest
  # Add stubs for required modules if not already loaded
  if !defined?(PlacekeyRails::Converter)
    module PlacekeyRails
      module Converter
        def self.placekey_to_h3(placekey)
          "8a2830828767fff" # Dummy value
        end
      end
      
      module H3Adapter
        def self.string_to_h3(h3_string)
          123456789 # Dummy value
        end
        
        def self.is_valid_cell(h3_index)
          true # Always valid for testing
        end
      end
    end
  end
  
  def self.test_validator
    puts "Testing PlacekeyRails::Validator.normalize_placekey_format"
    
    # Test cases that were failing
    test_case_1 = ["223227@5vg-82n-kzz", "223-227@5vg-82n-kzz", "what part needing dash (6 chars)"]
    test_case_2 = ["223@5vg-82n-kzz", "223-@5vg-82n-kzz", "what part needing dash (3 chars)"]
    
    # Run the tests
    [test_case_1, test_case_2].each do |input, expected, description|
      begin
        actual = PlacekeyRails::Validator.normalize_placekey_format(input)
        result = actual == expected ? "PASS" : "FAIL"
        puts "Test: #{description}"
        puts "  Input: #{input}"
        puts "  Expected: #{expected}"
        puts "  Actual: #{actual.inspect}"
        puts "  Result: #{result}"
        puts ""
      rescue => e
        puts "ERROR: #{e.message}"
        puts e.backtrace.join("\n")
      end
    end
  end
end

# Run the test
PlacekeyTest.test_validator
