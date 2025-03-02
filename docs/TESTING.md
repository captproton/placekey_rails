# Testing PlacekeyRails

This document outlines the testing approach for the PlacekeyRails gem.

## Running Tests

### Ruby/Rails Tests

The gem uses RSpec for testing. To run all tests:

```bash
bundle exec rspec
```

You can run specific test groups:

```bash
# Run model tests only
bundle exec rspec spec/models

# Run helper tests only
bundle exec rspec spec/helpers

# Run controller tests only
bundle exec rspec spec/controllers
```

### JavaScript Tests

The JavaScript components are tested using Jest. To run the JavaScript tests:

```bash
# From the dummy app directory
cd spec/dummy
yarn test

# Or from the gem root (if configured)
yarn test
```

## Test Structure

### Ruby/Rails Tests

- `spec/models/concerns/placekeyable_spec.rb` - Tests for the Placekeyable ActiveRecord concern
- `spec/helpers/placekey_helper_spec.rb` - Tests for the PlacekeyHelper
- `spec/helpers/form_helper_spec.rb` - Tests for the FormHelper
- `spec/controllers/placekey_rails/api/placekeys_controller_spec.rb` - Tests for the API controller
- `spec/routing/api_routes_spec.rb` - Tests for API routes

### JavaScript Tests

- `spec/javascript/controllers/map_controller.spec.js` - Tests for the Stimulus MapController

## Test Data

The tests use fixture data for Placekeys, coordinates, and geographic boundaries:

- Valid Placekey: `@5vg-82n-kzz`
- Coordinates: `37.7371, -122.44283` (San Francisco)

## Adding New Tests

When adding new features, please follow these guidelines:

1. Create test files in the appropriate directories
2. Use descriptive context and example names
3. Test both success and failure cases
4. Mock external dependencies (like API calls)
5. Keep tests focused and isolated

## Test Coverage

We aim for high test coverage across all components:

- Core functionality: 100% coverage
- ActiveRecord integration: 90%+ coverage
- View helpers: 90%+ coverage
- JavaScript components: 80%+ coverage

## Continuous Integration

Tests are run automatically on:
- Pull requests to main branches
- Merges to development/master
- Version tag creation

## Manual Testing

In addition to automated tests, please manually test:

1. Actual map rendering in browsers
2. Form interactions
3. API integrations with real data
4. Mobile responsiveness of components

## Writing Testable Code

When contributing, please follow these principles:

1. Keep methods small and focused
2. Inject dependencies where possible
3. Separate business logic from presentation
4. Use interfaces consistently
5. Document expected behaviors

## Troubleshooting Tests

### Ruby/Rails Tests

- Database issues: Try `bundle exec rake db:test:prepare`
- Random failures: Use `rspec --seed 1234` to reproduce
- Slow tests: Profile with `rspec --profile`

### JavaScript Tests

- Dependency issues: Run `yarn install`
- DOM testing issues: Check Jest setup and mocks
- Browser compatibility: Test with different browser environments

## Test Doubles

### Ruby/Rails Tests

We use RSpec's built-in doubles:

```ruby
# Example of mocking the API client
allow(PlacekeyRails).to receive(:default_client).and_return(double)
allow(PlacekeyRails).to receive(:lookup_placekey).and_return(expected_response)
```

### JavaScript Tests

We use Jest's mocking capabilities:

```javascript
// Example of mocking Leaflet
global.L = {
  map: jest.fn().mockReturnValue({
    setView: jest.fn().mockReturnThis()
  })
};
```

## Test-Driven Development

For new features, consider following TDD principles:

1. Write failing tests first
2. Implement the minimum code to pass
3. Refactor while keeping tests passing
