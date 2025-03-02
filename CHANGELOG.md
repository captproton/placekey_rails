# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive documentation with API reference
- Detailed examples and usage guides
- Troubleshooting documentation
- YARD configuration for API docs generation
- Performance optimizations for H3 operations
- Improved error handling throughout the library

## [0.1.0] - 2025-02-28

### Added
- Initial release
- Rails engine setup
- Basic Placekey conversion functionality
  - Converter for geographic coordinates to Placekeys
  - Converter for H3 indices to Placekeys
  - Parser for Placekey components
- H3Adapter for bridging between H3 gem and Placekey logic
- Validator for checking Placekey format validity
- Spatial operations
  - Neighboring Placekeys calculation
  - Distance calculation between Placekeys
  - Hexagon boundary and polygon conversions
  - GeoJSON, WKT, and polygon utilities
- API Client
  - Robust rate limiting mechanism
  - Batch processing support
  - DataFrame integration
  - Comprehensive error handling
- Full test suite with RSpec
- CI/CD setup with GitHub Actions

### Dependencies
- Rails >= 8.0.1
- H3 ~> 3.7.2
- RGeo ~> 3.0.1
- RGeo-GeoJSON ~> 2.2.0
- HTTParty ~> 0.22.0
- Rover-DF ~> 0.4.1
- JSBundling Rails
- Stimulus Rails
- Turbo Rails
- Tailwind CSS Rails

[Unreleased]: https://github.com/captproton/placekey_rails/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/captproton/placekey_rails/releases/tag/v0.1.0