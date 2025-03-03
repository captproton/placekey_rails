# Troubleshooting PlacekeyRails

This guide helps you troubleshoot common issues when working with the PlacekeyRails gem.

## Common Issues and Solutions

### Placekeyable Concern Issues

#### Issue: NoMethodError when calling `distance_to` on a Placekeyable model
**Cause**: The `respond_to?` method may not be handling the second parameter correctly.
**Solution**: Ensure that any objects passed to `distance_to` properly implement `respond_to?(:placekey, true)`.

#### Issue: Placekeys not being generated automatically
**Cause**: The required attributes may not be present or callbacks not running.
**Solution**: Ensure that latitude and longitude fields are present and valid before saving.

### Form Helper Issues

#### Issue: Form helpers not rendering expected fields
**Cause**: Parameter handling issues between the test suite and implementation.
**Solution**: Check the parameters you're passing to the form helpers and ensure they match the expected format.

#### Issue: JavaScript components not working with form helpers
**Cause**: Missing Stimulus controllers or improper data attributes.
**Solution**: Ensure you've included the JavaScript controllers in your application.js.

### API Client Issues

#### Issue: API calls failing with authentication errors
**Cause**: API key not set up correctly.
**Solution**: Call `PlacekeyRails.setup_client(your_api_key)` before making API calls.

#### Issue: Batch operations timing out
**Cause**: Too many requests in a single batch.
**Solution**: Reduce batch size by passing a smaller value to the `batch_size` parameter.

## Debugging Techniques

### Enabling Detailed Logging

Add this to your configuration:

```ruby
PlacekeyRails.configure do |config|
  config[:log_level] = :debug
end
```

### Debugging BatchProcessor

To debug batch operations, add a progress callback:

```ruby
PlacekeyRails.batch_geocode(collection) do |processed, successful|
  puts "Processed: #{processed}, Successful: #{successful}"
end
```

### Verifying API Responses

To see raw API responses, you can use:

```ruby
client = PlacekeyRails.default_client
response = client.lookup_placekey_raw(params)
puts response.body
```

## Getting Help

If you're still experiencing issues:

1. Check the [GitHub Issues](https://github.com/yourusername/placekey_rails/issues) for similar problems
2. Run the test suite to verify your installation
3. File a new issue with:
   - Ruby and Rails versions
   - PlacekeyRails version
   - Detailed description of the issue
   - Sample code to reproduce the problem