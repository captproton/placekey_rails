#!/bin/bash
cd /users/carltanner/dev/ruby/gems/placekey_rails
echo "Running validator specs..."
bundle exec rspec spec/lib/placekey_rails/validator_spec.rb
echo "Running H3Adapter specs..."
bundle exec rspec spec/lib/placekey_rails/h3_adapter_spec.rb
echo "Running client specs..."
bundle exec rspec spec/lib/placekey_rails/client_spec.rb
