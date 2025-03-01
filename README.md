# PlacekeyRails
Short description and motivation.

## Usage
How to use my plugin.

## Installation
Add this line to your application's Gemfile:

```ruby
gem "placekey_rails"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install placekey_rails
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Initial Testing
The engine comes with minimal verification specs to ensure proper setup:

1. Core specs (`spec/placekey_rails_spec.rb`):
   - Verify engine module and version
   - Confirm engine configuration
   - Check namespace isolation

2. Controller specs:
   - Verify base controller configuration
   - Confirm layout setup

To run the verification suite:
```
bundle exec rspec
```

### Adding Your Tests
- Model specs go in `spec/models/placekey_rails/`
- Controller specs go in `spec/controllers/placekey_rails/`
- Feature specs go in `spec/features/`
- Shared code goes in `spec/support/`

### Next Steps
After verifying the initial setup:
1. Add model specs for your domain models
2. Create controller specs for new endpoints
3. Write feature specs for user flows
4. Set up shared examples and contexts
