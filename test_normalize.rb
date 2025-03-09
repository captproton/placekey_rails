require_relative './lib/placekey_rails/validator'

# Test cases
test_cases = [
  [ "@5vg-82n-kzz", "@5vg-82n-kzz" ],
  [ "23b@5vg-82n-kzz", "@5vg-82n-kzz" ],
  [ "223227@5vg-82n-kzz", "223-227@5vg-82n-kzz" ],
  [ "223@5vg-82n-kzz", "223-@5vg-82n-kzz" ]
]

# Run the tests
results = test_cases.map do |input, expected|
  normalized = PlacekeyRails::Validator.normalize_placekey_format(input)
  {
    input: input,
    expected: expected,
    actual: normalized,
    passed: normalized == expected
  }
end

# Print results
puts "=== Placekey Normalization Tests ==="
results.each do |result|
  puts "Input: #{result[:input]}"
  puts "Expected: #{result[:expected]}"
  puts "Actual: #{result[:actual]}"
  puts "Passed: #{result[:passed]}"
  puts "---"
end

# Summary
passed = results.count { |r| r[:passed] }
total = results.size
puts "#{passed}/#{total} tests passed"
exit(passed == total ? 0 : 1)
