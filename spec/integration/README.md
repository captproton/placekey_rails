# PlacekeyRails Integration Tests

This directory contains integration tests for the PlacekeyRails gem. These tests verify that all components work together correctly.

## Test Categories

- `complete_workflow_spec.rb` - Tests the complete workflow from model creation to UI interaction
- `edge_cases_spec.rb` - Tests handling of error conditions and edge cases
- `javascript_integration_spec.rb` - Tests JavaScript component interactions
- `performance_spec.rb` - Tests performance with larger datasets

## Running Tests

### All Integration Tests

```bash
bundle exec rspec spec/integration
```

### JavaScript Tests

JavaScript tests require a JavaScript-capable driver like Selenium with Chrome:

```bash
ENABLE_JS_TESTS=true bundle exec rspec spec/integration/javascript_integration_spec.rb
```

### Performance Tests

Performance tests may take longer to run:

```bash
bundle exec rspec spec/integration/performance_spec.rb
```

## Test Helper Modules

The integration tests use helper modules from `spec/support`:

- `integration_test_helper.rb` - Common setup for integration tests
- `system_test_helper.rb` - Setup for system tests with JavaScript

## Documentation

For detailed information on the integration testing approach, see:
`docs/INTEGRATION_TESTING.md`
