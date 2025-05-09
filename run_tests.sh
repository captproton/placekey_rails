#!/bin/bash
cd /Users/carltanner/dev/ruby/gems/placekey_rails

# First run our standalone test
echo "Running standalone normalizer test..."
ruby test_normalizer.rb

# Now run the specific failing tests
echo -e "\nRunning the previously failing RSpec tests..."
bundle exec rspec spec/lib/placekey_rails/validator_spec.rb:25 spec/lib/placekey_rails/validator_spec.rb:30 spec/models/placekeyable_spec.rb:63
