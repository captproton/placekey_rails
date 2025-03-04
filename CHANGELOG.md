# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2025-03-03

### Added
- ActiveRecord integration through `Placekeyable` concern
  - Automatic Placekey generation from coordinates
  - Placekey validations and format checking
  - Spatial query methods for finding locations by distance
  - Address geocoding utilities
- View helpers for displaying and working with Placekeys
  - `PlacekeyHelper` for formatting and map integration
  - `FormHelper` for Placekey form fields
- JavaScript components with Stimulus.js controllers
  - Map visualization with Leaflet.js
  - Auto-generation of Placekeys from coordinates
  - Address lookup functionality
  - Placekey preview functionality
- API endpoints for JavaScript integration
  - Placekey info endpoint
  - Coordinate to Placekey conversion
  - Address to Placekey lookup
- Performance optimization features
  - Built-in caching system with LRU eviction
  - Batch processing for large datasets
  - Optimized spatial queries
  - Memory usage improvements
- Comprehensive documentation
  - Quick Start Guide
  - Installation Guide with platform-specific instructions
  - Compatibility Guide
  - Performance optimization guide
  - API reference documentation
  - Detailed examples and usage guides
  - Troubleshooting documentation

### Changed
- Enhanced error handling throughout the library
- Improved module configuration options
- More flexible API client options
- Fixed parameter handling in Placekeyable concern
- Fixed form helper field options handling
- Updated GitHub Actions workflow to use Ruby 3.2.2
- Fixed performance tests with more consistent timing

### Fixed
- Fixed `respond_to?` method signature in the Placekeyable concern to properly handle the optional second parameter
- Fixed parameter handling in the FormHelper for better compatibility with Rails conventions
- Fixed BatchProcessor parameter handling to match test expectations
- Properly mocked Placekey validation in tests to avoid validation errors
- Fixed GitHub Actions CI to use the correct Ruby version

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

[Unreleased]: https://github.com/captproton/placekey_rails/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/captproton/placekey_rails/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/captproton/placekey_rails/releases/tag/v0.1.0