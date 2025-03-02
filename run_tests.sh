#!/bin/bash
cd /users/carltanner/dev/ruby/gems/placekey_rails
echo "Running validator specs..."
bundle exec rspec spec/lib/placekey_rails/validator_spec.rb
echo "Running H3Adapter specs..."
bundle exec rspec spec/lib/placekey_rails/h3_adapter_spec.rb
echo "Running cache specs..."
bundle exec rspec spec/lib/placekey_rails/cache_spec.rb
echo "Running module cache specs..."
bundle exec rspec spec/lib/placekey_rails/module_cache_spec.rb
echo "Running client specs..."
bundle exec rspec spec/lib/placekey_rails/client_spec.rb
echo "Running Placekeyable concern specs..."
bundle exec rspec spec/models/placekeyable_spec.rb
echo "Running helper specs..."
bundle exec rspec spec/helpers/
echo "Running API controller specs..."
bundle exec rspec spec/controllers/placekey_rails/api/
