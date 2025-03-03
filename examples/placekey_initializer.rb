# config/initializers/placekey.rb

# Configure the Placekey API client with your API key
# Obtain an API key from https://placekey.io/
PlacekeyRails.setup_client(
  ENV['PLACEKEY_API_KEY'],
  max_retries: 5,
  logger: Rails.logger
)

# Enable caching to improve performance and reduce API calls
# This is optional but recommended for production environments
PlacekeyRails.enable_caching(max_size: 1000)

# Configure default options for the API client
PlacekeyRails.configure do |config|
  # Default country code to use for address lookups when not specified
  config.default_country_code = 'US'

  # Whether to validate placekeys automatically
  config.validate_placekeys = true

  # Default timeout for API requests (in seconds)
  config.api_timeout = 10

  # Whether to raise exceptions on API errors
  config.raise_on_api_error = Rails.env.development?
end

# Require the PlacekeyRails JavaScript module in your application.js
# //= require placekey_rails

# If using Webpack/Webpacker, add this to your application.js:
# import { PlacekeyRails } from 'placekey_rails'
# PlacekeyRails.initialize()
