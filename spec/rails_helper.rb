require 'spec_helper'
require File.expand_path('../dummy/config/environment', __FILE__)
require 'rspec/rails'
require_relative 'lib/spec_helper'
require 'h3'

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # We've already set up H3 mocks in spec/lib/spec_helper.rb
  # No need to add more mocking here as it could cause conflicts
end
