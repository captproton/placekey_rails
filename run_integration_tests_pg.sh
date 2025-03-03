#!/bin/bash

# Script to run PlacekeyRails integration tests with PostgreSQL

echo "Running PlacekeyRails integration tests with PostgreSQL..."
echo "========================================================="

# Make sure PostgreSQL is properly set up
if ! bundle info pg > /dev/null 2>&1; then
  echo "PostgreSQL gem is not installed. Please run setup_postgres_for_tests.sh first."
  exit 1
fi

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

echo "========================================================="
echo "Integration tests completed!"
