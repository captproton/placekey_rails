#!/bin/bash

# Script to set up PostgreSQL database for PlacekeyRails tests

echo "Setting up PostgreSQL database for PlacekeyRails tests..."
echo "========================================================="

# Install PostgreSQL gem if not already installed
if ! bundle info pg > /dev/null 2>&1; then
  echo "Installing PostgreSQL gem..."
  bundle add pg
fi

# Remove SQLite gem if present
if bundle info sqlite3 > /dev/null 2>&1; then
  echo "Removing SQLite gem..."
  bundle remove sqlite3
fi

# Create and migrate databases
echo "Creating and migrating databases..."
cd spec/dummy
RAILS_ENV=development bin/rails db:drop db:create db:migrate
RAILS_ENV=test bin/rails db:drop db:create db:migrate
cd ../..

echo "========================================================="
echo "PostgreSQL setup complete!"
echo "You can now run your tests with: bundle exec rspec"
