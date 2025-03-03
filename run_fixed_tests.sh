#!/bin/bash
cd /users/carltanner/dev/ruby/gems/placekey_rails
bundle exec rspec spec/models/placekeyable_spec.rb spec/helpers/form_helper_spec.rb spec/lib/placekey_rails/module_config_spec.rb
