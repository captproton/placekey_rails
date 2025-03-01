#!/bin/bash
cd /users/carltanner/dev/ruby/gems/placekey_rails
echo "Running all specs except dummy app..."
bundle exec rspec --exclude-pattern "spec/dummy/**/*_spec.rb"
