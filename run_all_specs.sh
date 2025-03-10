#!/bin/bash
cd /Users/carltanner/dev/ruby/gems/placekey_rails

# Run the standalone validator tests to confirm our fix works
echo "Running standalone normalizer test..."
ruby test_normalizer.rb

# Run the specific tests that were failing to confirm they now pass
echo -e "\nRunning the previously failing RSpec tests..."
bundle exec rspec spec/lib/placekey_rails/validator_spec.rb:25 spec/lib/placekey_rails/validator_spec.rb:30 spec/models/placekeyable_spec.rb:63

# Run the entire test suite to make sure we didn't break anything else
echo -e "\nRunning all RSpec tests..."
bundle exec rspec
