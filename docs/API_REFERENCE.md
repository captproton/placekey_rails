# PlacekeyRails API Reference

This document provides a complete reference for the PlacekeyRails gem API.

## Table of Contents

- [Module Methods](#module-methods)
  - [Conversion Methods](#conversion-methods)
  - [Validation Methods](#validation-methods)
  - [Spatial Methods](#spatial-methods)
  - [API Client Methods](#api-client-methods)
- [Components](#components)
  - [Converter](#converter)
  - [Validator](#validator)
  - [Spatial](#spatial)
  - [Client](#client)
  - [H3Adapter](#h3adapter)

## Module Methods

The `PlacekeyRails` module provides convenient access to the functionality of the gem without needing to use the individual components directly.

### Conversion Methods

#### `geo_to_placekey(lat, long)`

Convert latitude and longitude into a Placekey.

**Parameters:**
- `lat`: Latitude (float)
- `long`: Longitude (float)

**Returns:** Placekey (string)

**Example:**
```ruby
placekey = PlacekeyRails.geo_to_placekey(37.7371, -122.44283)
# => "@5vg-82n-kzz"
```

#### `placekey_to_geo(placekey)`

Convert a Placekey into a (latitude, longitude) tuple.

**Parameters:**
- `placekey`: Placekey (string)

**Returns:** [latitude, longitude] array of floats

**Example:**
```ruby
lat, long = PlacekeyRails.placekey_to_geo("@5vg-82n-kzz")
# => [37.7371, -122.44283]
```

#### `h3_to_placekey(h3_string)`

Convert an H3 hexadecimal string into a Placekey string.

**Parameters:**
- `h3_string`: H3 (string)

**Returns:** Placekey (string)

**Example:**
```ruby
placekey = PlacekeyRails.h3_to_placekey("8a2830828767fff")
# => "@5vg-7gq-tvz"
```

#### `placekey_to_h3(placekey)`

Convert a Placekey string into an H3 string.

**Parameters:**
- `placekey`: Placekey (string)

**Returns:** H3 (string)

**Example:**
```ruby
h3 = PlacekeyRails.placekey_to_h3("@5vg-7gq-tvz")
# => "8a2830828767fff"
```

### Validation Methods

#### `placekey_format_is_valid(placekey)`

Boolean for whether or not the format of a Placekey is valid, including checks for valid encoding of location.

**Parameters:**
- `placekey`: Placekey (string)

**Returns:** True if the Placekey is valid, False otherwise

**Example:**
```ruby
PlacekeyRails.placekey_format_is_valid("@5vg-7gq-tvz")
# => true

PlacekeyRails.placekey_format_is_valid("invalid-format")
# => false
```

### Spatial Methods

#### `get_neighboring_placekeys(placekey, dist=1)`

Return the unordered set of Placekeys whose grid distance is <= `dist` from the given Placekey. In this context, grid distance refers to the number of H3 cells between two H3 cells, so that neighboring cells have distance 1, neighbors of neighbors have distance 2, etc.

**Parameters:**
- `placekey`: Placekey (string)
- `dist`: Size of the neighborhood around the input Placekey to return (int)

**Returns:** Set of Placekeys

**Example:**
```ruby
neighbors = PlacekeyRails.get_neighboring_placekeys("@5vg-7gq-tvz", 1)
# => #<Set: {"@5vg-7gq-tvz", "@5vg-7gq-tuz", ...}>
```

#### `placekey_distance(placekey_1, placekey_2)`

Return the distance in meters between the centers of two Placekeys.

**Parameters:**
- `placekey_1`: Placekey (string)
- `placekey_2`: Placekey (string)

**Returns:** Distance in meters (float)

**Example:**
```ruby
distance = PlacekeyRails.placekey_distance("@5vg-7gq-tvz", "@5vg-82n-kzz")
# => 1242.8
```

#### `get_prefix_distance_dict()`

Return a dictionary mapping the length of a shared Placekey prefix to the maximal distance in meters between two Placekeys sharing a prefix of that length.

**Returns:** Dictionary mapping prefix length -> distance (m)

**Example:**
```ruby
prefix_distances = PlacekeyRails.get_prefix_distance_dict
# => {0=>20040000.0, 1=>20040000.0, 2=>2777000.0, ...}
```

#### `placekey_to_hex_boundary(placekey, geo_json=false)`

Given a Placekey, return the coordinates of the boundary of the hexagon.

**Parameters:**
- `placekey`: Placekey (string)
- `geo_json`: If true, return coordinates in GeoJSON format (longitude, latitude).
  If false (default), coordinates will be (latitude, longitude).

**Returns:** Array of coordinate tuples

**Example:**
```ruby
boundary = PlacekeyRails.placekey_to_hex_boundary("@5vg-7gq-tvz")
# => [[37.775, -122.443], [37.774, -122.441], ...]
```

#### `placekey_to_polygon(placekey, geo_json=false)`

Get the boundary RGeo::Polygon for a Placekey.

**Parameters:**
- `placekey`: Placekey (string)
- `geo_json`: If true, use GeoJSON coordinate ordering (longitude, latitude).
  If false (default), use (latitude, longitude).

**Returns:** An RGeo polygon object

**Example:**
```ruby
polygon = PlacekeyRails.placekey_to_polygon("@5vg-7gq-tvz")
```

#### `placekey_to_wkt(placekey, geo_json=false)`

Convert a Placekey into the WKT (Well-Known Text) string for the corresponding hexagon.

**Parameters:**
- `placekey`: Placekey (string)
- `geo_json`: If true, use GeoJSON coordinate ordering

**Returns:** WKT polygon (string)

**Example:**
```ruby
wkt = PlacekeyRails.placekey_to_wkt("@5vg-7gq-tvz")
# => "POLYGON((37.775 -122.443, 37.774 -122.441, ...))"
```

#### `placekey_to_geojson(placekey)`

Convert a Placekey into a GeoJSON dictionary.

**Parameters:**
- `placekey`: Placekey (string)

**Returns:** Dictionary describing the polygon in GeoJSON format

**Example:**
```ruby
geojson = PlacekeyRails.placekey_to_geojson("@5vg-7gq-tvz")
# => {"type"=>"Feature", "geometry"=>{"type"=>"Polygon", "coordinates"=>[...]}, ...}
```

#### `polygon_to_placekeys(poly, include_touching=false, geo_json=false)`

Given an RGeo::Polygon, return Placekeys contained in or intersecting the boundary of the polygon.

**Parameters:**
- `poly`: RGeo::Polygon object
- `include_touching`: If true, include Placekeys whose hexagon boundary only touches
  that of the input polygon. Default is false.
- `geo_json`: If true, assume coordinates in `poly` are in GeoJSON format:
  (longitude, latitude). If false (default), assume (latitude, longitude).

**Returns:** Hash with keys 'interior' and 'boundary' containing arrays of Placekeys

**Example:**
```ruby
result = PlacekeyRails.polygon_to_placekeys(polygon)
# => {interior: ["@5vg-7gq-tvz", ...], boundary: ["@5vg-82n-kzz", ...]}
```

#### `wkt_to_placekeys(wkt, include_touching=false, geo_json=false)`

Given a WKT description of a polygon, return Placekeys contained in or intersecting the boundary of the polygon.

**Parameters:**
- `wkt`: Well-Known Text object (string)
- `include_touching`: If true, include Placekeys whose hexagon boundary only touches
  that of the input polygon. Default is false.
- `geo_json`: If true, assume GeoJSON coordinate ordering. Default is false.

**Returns:** Hash with keys 'interior' and 'boundary' containing arrays of Placekeys

**Example:**
```ruby
result = PlacekeyRails.wkt_to_placekeys("POLYGON((...))")
# => {interior: ["@5vg-7gq-tvz", ...], boundary: ["@5vg-82n-kzz", ...]}
```

#### `geojson_to_placekeys(geojson, include_touching=false, geo_json=true)`

Given a GeoJSON description of a polygon, return Placekeys contained in or intersecting the boundary of the polygon.

**Parameters:**
- `geojson`: GeoJSON object (string or hash)
- `include_touching`: If true, include Placekeys whose hexagon boundary only touches
  that of the input polygon. Default is false.
- `geo_json`: If true (default), assume GeoJSON coordinate ordering.

**Returns:** Hash with keys 'interior' and 'boundary' containing arrays of Placekeys

**Example:**
```ruby
result = PlacekeyRails.geojson_to_placekeys(geojson_data)
# => {interior: ["@5vg-7gq-tvz", ...], boundary: ["@5vg-82n-kzz", ...]}
```

### API Client Methods

#### `setup_client(api_key, options={})`

Set up a default client for convenience methods.

**Parameters:**
- `api_key`: The Placekey API key (string)
- `options`: Additional options for the client (hash)

**Example:**
```ruby
PlacekeyRails.setup_client("your-api-key")
```

#### `list_free_datasets()`

List all free datasets available from the Placekey API.

**Returns:** An array of dataset information

**Example:**
```ruby
datasets = PlacekeyRails.list_free_datasets
```

#### `return_free_datasets_location_by_name(name, url: false)`

Get the location of a free dataset by name.

**Parameters:**
- `name`: Dataset name (string)
- `url`: Whether to return a URL instead of file path (boolean)

**Returns:** Path or URL to the dataset

**Example:**
```ruby
location = PlacekeyRails.return_free_datasets_location_by_name("safegraph_core_poi")
```

#### `return_free_dataset_joins_by_name(names, url: false)`

Get joins between multiple free datasets.

**Parameters:**
- `names`: Array of dataset names (array)
- `url`: Whether to return URLs instead of file paths (boolean)

**Returns:** Joins between the datasets

**Example:**
```ruby
joins = PlacekeyRails.return_free_dataset_joins_by_name(["safegraph_core_poi", "safegraph_neighborhood_patterns"])
```

#### `lookup_placekey(params, fields=nil)`

Look up a Placekey for a location.

**Parameters:**
- `params`: The location parameters (hash)
- `fields`: Optional fields to request (array)

**Returns:** The API response (hash)

**Example:**
```ruby
# First set up the client
PlacekeyRails.setup_client("your-api-key")

# Then look up a Placekey
result = PlacekeyRails.lookup_placekey({
  street_address: "598 Portola Dr",
  city: "San Francisco",
  region: "CA",
  postal_code: "94131"
})
```

#### `lookup_placekeys(places, fields=nil, batch_size=100, verbose=false)`

Look up Placekeys for multiple locations.

**Parameters:**
- `places`: The locations (array of hashes)
- `fields`: Optional fields to request (array)
- `batch_size`: Batch size for requests (integer)
- `verbose`: Whether to log detailed information (boolean)

**Returns:** The API responses (array of hashes)

**Example:**
```ruby
# First set up the client
PlacekeyRails.setup_client("your-api-key")

# Then look up multiple Placekeys
places = [
  {
    street_address: "1543 Mission Street, Floor 3",
    city: "San Francisco",
    region: "CA",
    postal_code: "94105"
  },
  {
    latitude: 37.7371,
    longitude: -122.44283
  }
]
results = PlacekeyRails.lookup_placekeys(places)
```

#### `placekey_dataframe(dataframe, column_mapping, fields=nil, batch_size=100, verbose=false)`

Process a dataframe with the Placekey API.

**Parameters:**
- `dataframe`: The DataFrame to process (Rover::DataFrame)
- `column_mapping`: Mapping from API fields to DataFrame columns (hash)
- `fields`: Optional fields to request (array)
- `batch_size`: Batch size for requests (integer)
- `verbose`: Whether to log detailed information (boolean)

**Returns:** The processed DataFrame (Rover::DataFrame)

**Example:**
```ruby
# First set up the client
PlacekeyRails.setup_client("your-api-key")

# Then process a DataFrame
df = Rover::DataFrame.new(data)
column_mapping = {
  "street_address" => "address",
  "city" => "city",
  "region" => "state",
  "postal_code" => "zip"
}
result_df = PlacekeyRails.placekey_dataframe(df, column_mapping)
```

## Components

### Converter

The `PlacekeyRails::Converter` module handles conversion between different formats (Placekey, H3, geographic coordinates).

See the module methods for details.

### Validator

The `PlacekeyRails::Validator` module provides validation of Placekey formats.

See the module methods for details.

### Spatial

The `PlacekeyRails::Spatial` module performs spatial operations (boundaries, distances, etc.).

See the module methods for details.

### Client

The `PlacekeyRails::Client` class interfaces with the Placekey API.

#### Constructor

##### `initialize(api_key, options = {})`

**Parameters:**
- `api_key`: Placekey API key (string)
- `options`: Hash of options:
  - `max_retries`: Maximum number of times to retry a failed request (default: 20)
  - `logger`: Custom logger (default: Rails.logger)
  - `user_agent_comment`: String to append to user agent

#### Methods

See the module client methods for details.

### H3Adapter

The `PlacekeyRails::H3Adapter` module provides an interface to the H3 library functionality.

This is an internal module used by the other components, and you generally shouldn't need to use it directly.
