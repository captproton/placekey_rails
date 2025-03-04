# Integration Testing Guide for PlacekeyRails

This guide documents the integration testing approach for the PlacekeyRails gem, covering comprehensive tests that verify the complete workflow and component interactions.

## Overview

Our integration testing approach focuses on ensuring that all components of the PlacekeyRails gem work together correctly. This includes:

1. **Complete workflow testing** - Testing the entire process from model creation to API interaction
2. **Edge case handling** - Verifying the system handles errors and unusual inputs gracefully
3. **JavaScript component integration** - Testing UI components and interactions
4. **Performance testing** - Measuring system behavior with larger datasets

## Test Suite Structure

The integration tests are organized in the following categories:

- `complete_workflow_spec.rb` - Tests the core functionality from end to end
- `edge_cases_spec.rb` - Tests error conditions and edge cases
- `javascript_integration_spec.rb` - Tests JavaScript component interactions
- `performance_spec.rb` - Tests system performance with larger datasets

## Setting Up for Integration Testing

### Prerequisites

1. A properly configured testing environment with:
   - RSpec
   - DatabaseCleaner
   - Factory Bot or test fixtures
   - Capybara (for JavaScript testing)
   - A JavaScript-capable driver like Selenium or Chrome headless (for system tests)

### Running Integration Tests

Run the full integration test suite:

```bash
bundle exec rspec spec/integration
```

Run a specific integration test category:

```bash
bundle exec rspec spec/integration/complete_workflow_spec.rb
```

Enable JavaScript tests (requires properly configured JS driver):

```bash
ENABLE_JS_TESTS=true bundle exec rspec spec/integration/javascript_integration_spec.rb
```

## Test Categories

### Complete Workflow Tests

These tests verify that all components of the system work together correctly, including:

- Model with Placekeyable concern properly handling coordinates
- Placekey generation and validation
- Spatial operations (boundary, distance, neighbors)
- Batch processing
- Form interactions

### Edge Case Tests

These tests verify that the system handles unusual inputs and error conditions gracefully:

- Invalid coordinates and placekeys
- API errors and connection issues
- Rate limiting scenarios
- Input validation errors
- Recovery from temporary failures

### JavaScript Component Tests

These tests verify that the UI components work correctly:

- Coordinate input and placekey generation
- Map display and interaction
- Address lookup functionality
- Form submission and validation
- Error handling and messaging

### Performance Tests

These tests verify that the system performs well with larger datasets:

- Batch processing performance and scaling
- Spatial query performance
- Memory usage
- Concurrent operations

## Best Practices

1. **Isolate external dependencies** - Mock API calls and external services to focus on testing your code, not external systems.

2. **Use realistic data** - Test with data that resembles real-world usage to catch edge cases.

3. **Test complete workflows** - Don't just test individual components, make sure they work together.

4. **Include error scenarios** - Test how the system handles errors and edge cases.

5. **Measure performance** - Include tests that verify performance doesn't degrade unexpectedly.

6. **Test UI interactions** - Make sure JavaScript components work correctly with your Rails code.

## Mocking Strategies

### API Client Mocking

For integration tests, we mock the Placekey API client to avoid real API calls:

```ruby
let(:api_client) { instance_double(PlacekeyRails::Client) }

before do
  allow(PlacekeyRails).to receive(:default_client).and_return(api_client)
  
  allow(api_client).to receive(:lookup_placekey) do |params|
    lat = params[:latitude]
    lng = params[:longitude]
    
    {
      "placekey" => "@#{lat.to_i}-#{lng.to_i}-xyz",
      "query_id" => "test_#{lat}_#{lng}"
    }
  end
end
```

### Module Function Mocking

For spatial operations, we mock the core module functions:

```ruby
before do
  allow(PlacekeyRails).to receive(:geo_to_placekey) do |lat, lng|
    "@#{lat.to_i}-#{lng.to_i}-xyz"
  end
  
  allow(PlacekeyRails).to receive(:placekey_to_geo) do |placekey|
    parts = placekey.gsub('@', '').split('-')
    [parts[0].to_f, -parts[1].to_f]
  end
  
  allow(PlacekeyRails).to receive(:get_neighboring_placekeys).and_return(
    ["@5vg-7gq-tvz", "@5vg-7gq-tvy"]
  )
end
```

## Debugging Failed Tests

When integration tests fail, consider these debugging strategies:

1. **Check logs** - Review test logs for errors and warnings.
2. **Isolate components** - If an integration test fails, test each component independently.
3. **Step through with pry** - Insert `binding.pry` at key points to debug test execution.
4. **Inspect the DOM** - For JavaScript tests, use `save_and_open_page` to see the page state.
5. **Validate mocks** - Ensure your mocks reflect actual system behavior accurately.

## Extending the Test Suite

When adding new features to PlacekeyRails, follow these guidelines for integration tests:

1. **Add to existing categories** - Add your tests to the appropriate existing category.
2. **Test both success and failure** - Include tests for both happy path and error conditions.
3. **Verify UI interactions** - If your feature has a UI component, add JavaScript tests.
4. **Include performance considerations** - Add performance tests for features that might impact performance.

## Continuous Integration

The integration test suite is designed to run in CI environments. Important notes:

1. **JavaScript tests** - Require a JavaScript-capable driver, which may need special setup in CI.
2. **Database tests** - Tests using AR models require a test database.
3. **Performance tests** - May need configuration for different CI environments.

## Future Improvements

Areas for future testing improvements:

1. **Additional system tests** - More comprehensive UI testing with Capybara.
2. **Visual regression testing** - Testing UI components for visual regressions.
3. **Stress testing** - Testing system behavior under heavy load.
4. **Cross-browser testing** - Testing JavaScript components across browsers.
