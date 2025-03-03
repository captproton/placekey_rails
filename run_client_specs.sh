#!/bin/bash
cd /users/carltanner/dev/ruby/gems/placekey_rails
bundle exec rspec spec/lib/placekey_rails/client_dataframe_spec.rb spec/lib/placekey_rails/module_client_spec.rb spec/lib/placekey_rails/rate_limiter_spec.rb
