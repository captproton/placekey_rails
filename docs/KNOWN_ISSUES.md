# Known Issues in PlacekeyRails

This document outlines current known issues in the PlacekeyRails gem that are being tracked for resolution.

## Core Component Issues

### Placekeyable Concern
- **Issue**: `respond_to?` method in test classes doesn't match Ruby's standard signature, causing test failures
- **Impact**: Distance calculations between placekeyable objects may fail
- **Fix Status**: Patch submitted, awaiting testing
- **Workaround**: Ensure any objects passed to `distance_to` properly implement `respond_to?(:placekey, true)`

### BatchProcessor
- **Issue**: Parameter handling inconsistencies between implementation and tests
- **Impact**: Some batch operations may not work as expected
- **Fix Status**: Under investigation
- **Workaround**: Use explicit keyword arguments when calling batch methods

### FormHelper
- **Issue**: Field options handling doesn't match test expectations
- **Impact**: Some form fields may not have expected attributes
- **Fix Status**: Patch in progress
- **Workaround**: Use simpler option formats

## API Integration Issues

### API Rate Limiting
- **Issue**: No built-in handling for API rate limit exceeded scenarios
- **Impact**: Batch operations may fail when API limits are reached
- **Fix Status**: Planned for next release
- **Workaround**: Use smaller batch sizes and add manual retry logic

### API Client Configuration
- **Issue**: Client configuration is not persisted across application restarts
- **Impact**: Need to reconfigure client after application restarts
- **Fix Status**: Planned for future release
- **Workaround**: Configure client in an initializer file

## JavaScript Component Issues

### Map Component Safari Compatibility
- **Issue**: Map component rendering issues in Safari browser
- **Impact**: Maps may not display correctly in Safari
- **Fix Status**: Under investigation
- **Workaround**: Use Chrome or Firefox for map-related features

### Stimulus Controller Conflicts
- **Issue**: Potential conflicts with other Stimulus controllers using similar targets
- **Impact**: JavaScript components may not initialize properly in some applications
- **Fix Status**: Planned for future release
- **Workaround**: Namespace custom Stimulus controllers to avoid conflicts

## Performance Issues

### Large Dataset Handling
- **Issue**: Memory usage can grow excessive when processing very large datasets
- **Impact**: Out of memory errors possible with large collections
- **Fix Status**: Optimization planned for future release
- **Workaround**: Process data in smaller batches

### Caching Implementation
- **Issue**: Cache does not respect TTL (Time-To-Live)
- **Impact**: Cached data may become stale
- **Fix Status**: Planned for next release
- **Workaround**: Manually clear cache when needed with `PlacekeyRails.clear_cache`

## Documentation Issues

### Missing Documentation
- **Issue**: Some advanced features lack comprehensive documentation
- **Impact**: Difficult to use some advanced features without examples
- **Fix Status**: Documentation updates in progress
- **Workaround**: Check the test files for usage examples

### Outdated Examples
- **Issue**: Some examples in documentation don't match current API
- **Impact**: Copy-pasted examples may not work
- **Fix Status**: Documentation updates in progress
- **Workaround**: Refer to source code for current method signatures

## Reporting New Issues

If you encounter issues not listed here, please report them on GitHub:
https://github.com/yourname/placekey_rails/issues

Please include:
- PlacekeyRails version
- Ruby and Rails versions
- Detailed description of the issue
- Minimal code sample that reproduces the issue
- Expected vs. actual behavior