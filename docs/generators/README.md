# PlacekeyRails Generators

This directory contains documentation for the various generators provided by the PlacekeyRails gem.

## Available Generators

### Install Generator

The Install Generator automates the setup process for PlacekeyRails in your Rails application. It creates initializers, migrations, and updates models to include the Placekeyable concern.

For detailed documentation, see [Install Generator Documentation](../INSTALL_GENERATOR.md).

## Usage Examples

### Basic Installation

```bash
rails generate placekey_rails:install
```

### Setting Up With API Key

```bash
rails generate placekey_rails:install --api_key=your_api_key_here
```

### Using a Custom Model

```bash
rails generate placekey_rails:install --model=venue
```

### Skipping Certain Components

```bash
# Skip JavaScript integration
rails generate placekey_rails:install --skip_javascript

# Skip model modification
rails generate placekey_rails:install --skip_model

# Skip initializer creation
rails generate placekey_rails:install --skip_initializer

# Skip migration creation
rails generate placekey_rails:install --skip_migration
```

## Development

When adding new generators, please follow these guidelines:

1. Place generator code under `lib/generators/placekey_rails/`
2. Create comprehensive tests in `spec/generators/placekey_rails/`
3. Document the generator in `docs/generators/`
4. Update this README to include the new generator

For more information on Rails generators, see the [Rails Guides](https://guides.rubyonrails.org/generators.html).
