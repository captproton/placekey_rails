#!/bin/bash

# Script to run PlacekeyRails integration tests

echo "Running PlacekeyRails integration tests..."
echo "==========================================="

# Run database migrations for the dummy app
echo "Setting up test database..."
cd spec/dummy
RAILS_ENV=test bin/rails db:migrate
cd ../..

# Run the integration tests
echo "Running integration tests..."
bundle exec rspec spec/integration

# Optionally run JavaScript tests if selenium is available
if bundle list | grep -q "selenium-webdriver"; then
  echo "Running JavaScript integration tests..."
  ENABLE_JS_TESTS=true bundle exec rspec spec/integration/javascript_integration_spec.rb
else
  echo "Skipping JavaScript tests (selenium-webdriver not installed)"
  echo "To run JavaScript tests: gem install selenium-webdriver"
fi

echo "==========================================="
echo "Integration tests completed!"
