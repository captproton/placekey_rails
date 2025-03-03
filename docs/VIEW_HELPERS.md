# View Helpers

PlacekeyRails includes several view helpers to simplify working with Placekeys in your views and forms.

## Table of Contents

- [PlacekeyHelper](#placekeyhelper)
  - [Format and Display](#format-and-display)
  - [Map Integration](#map-integration)
- [FormHelper](#formhelper)
  - [Basic Placekey Fields](#basic-placekey-fields)
  - [Coordinate Fields](#coordinate-fields)
  - [Address Fields](#address-fields)

## PlacekeyHelper

Include the helper in your controllers or views:

```ruby
# In a controller
class LocationsController < ApplicationController
  helper PlacekeyRails::PlacekeyHelper
end

# Or directly in a view
<% helper PlacekeyRails::PlacekeyHelper %>
```

### Format and Display

#### `format_placekey(placekey, options = {})`

Format a Placekey for display, optionally highlighting the what/where parts.

```erb
<%= format_placekey("@5vg-82n-kzz") %>
<!-- Renders: <span class="placekey">@5vg-82n-kzz</span> -->

<%= format_placekey("abc-123@5vg-82n-kzz") %>
<!-- Renders:
<span class="placekey">
  <span class="placekey-what">abc-123</span>
  <span class="placekey-separator">@</span>
  <span class="placekey-where">5vg-82n-kzz</span>
</span>
-->

<!-- With custom classes -->
<%= format_placekey("abc-123@5vg-82n-kzz", what_class: "poi-id", where_class: "hex-id") %>
```

#### `format_placekey_distance(distance_meters)`

Format a distance in a human-readable way.

```erb
<%= format_placekey_distance(1500) %>
<!-- Renders: 1.5 km -->

<%= format_placekey_distance(750) %>
<!-- Renders: 750.0 m -->
```

### Map Integration

#### `placekey_map_data(placekey)`

Generate map data for a Placekey that can be used with mapping libraries.

```erb
<% map_data = placekey_map_data("@5vg-82n-kzz") %>
<!-- Returns:
{
  placekey: "@5vg-82n-kzz",
  center: { lat: 37.7371, lng: -122.44283 },
  boundary: [[-122.443, 37.775], ...], # in GeoJSON format
  geojson: { ... } # Complete GeoJSON object
}
-->
```

#### `placekeys_map_data(placekeys)`

Generate map data for a collection of Placekeys.

```erb
<% placekeys = Location.all.pluck(:placekey) %>
<% map_data = placekeys_map_data(placekeys) %>
<!-- Returns an array of map data for each Placekey -->
```

#### `leaflet_map_for_placekey(placekey, options = {})`

Generate a Leaflet.js map for a Placekey.

```erb
<%= leaflet_map_for_placekey("@5vg-82n-kzz") %>
<!-- Renders a div with data attributes for the Stimulus controller -->

<%= leaflet_map_for_placekey("@5vg-82n-kzz", height: "300px", zoom: 12) %>
```

#### `placekey_card(placekey, options = {})`

Generate a card display for a Placekey with optional info and map.

```erb
<%= placekey_card("@5vg-82n-kzz") %>
<!-- Renders a card with Placekey, coordinates, and map -->

<%= placekey_card("@5vg-82n-kzz", title: "Store Location", show_coords: false) %>
<!-- Renders card with custom title and no coordinates -->

<%= placekey_card("@5vg-82n-kzz") do %>
  <div class="additional-info">
    <p>Additional information about this location</p>
  </div>
<% end %>
```

#### `external_map_link_for_placekey(placekey, service = :google_maps, link_text = nil)`

Generate a link to an external map service showing the Placekey location.

```erb
<%= external_map_link_for_placekey("@5vg-82n-kzz") %>
<!-- Renders: <a href="https://www.google.com/maps/search/?api=1&query=37.7371,-122.44283" target="_blank" class="placekey-external-map-link">View on Google Maps</a> -->

<%= external_map_link_for_placekey("@5vg-82n-kzz", :openstreetmap, "Show on OSM") %>
<!-- Renders link to OpenStreetMap with custom text -->
```

## FormHelper

Include the helper in your controllers or forms:

```ruby
# In a controller
class LocationsController < ApplicationController
  helper PlacekeyRails::FormHelper
end

# Or directly in a view
<% helper PlacekeyRails::FormHelper %>
```

### Basic Placekey Fields

#### `placekey_field(form, options = {})`

Generate a Placekey form field with validation and autocomplete.

```erb
<%= form_with(model: @location) do |form| %>
  <%= placekey_field(form) %>
<% end %>

<!-- With custom options -->
<%= placekey_field(form, help: "Enter the location's unique Placekey", preview: false) %>
```

### Coordinate Fields

#### `placekey_coordinate_fields(form, options = {})`

Generate coordinate fields that automatically generate a Placekey.

```erb
<%= form_with(model: @location) do |form| %>
  <%= placekey_coordinate_fields(form) %>
<% end %>

<!-- With custom options -->
<%= placekey_coordinate_fields(form, 
      latitude: { step: "0.0001" },
      longitude: { step: "0.0001" },
      readonly_placekey: false
    ) %>
```

### Address Fields

#### `placekey_address_fields(form, options = {})`

Generate an address form that can lookup a Placekey via the API.

```erb
<%= form_with(model: @location) do |form| %>
  <%= placekey_address_fields(form) %>
<% end %>

<!-- With custom options -->
<%= placekey_address_fields(form,
      address_field: :street,  # Use custom field names
      city_field: :town,
      region_field: :state,
      compact_layout: true,   # Display city/region/postal code in a row
      preview: true           # Show map preview
    ) %>
```

## JavaScript Components

The view helpers rely on Stimulus.js controllers that provide the interactive functionality. These are automatically included when you use the gem.

### Available Controllers

- `placekey-map` - Displays a Placekey on a Leaflet map
- `placekey-generator` - Automatically generates a Placekey from coordinates
- `placekey-lookup` - Looks up a Placekey from an address
- `placekey-preview` - Shows a preview map for a Placekey

### Including the JavaScript

In your application's JavaScript, include the PlacekeyRails JavaScript:

```javascript
// app/javascript/application.js
import "placekey_rails"
```

### CSS Styling

To style the Placekey components, add this to your CSS:

```css
/* Placekey formatting */
.placekey {
  font-family: monospace;
  white-space: nowrap;
}

.placekey-what {
  color: #2c5282;
}

.placekey-separator {
  color: #4a5568;
}

.placekey-where {
  color: #2b6cb0;
}

/* Form styling */
.placekey-field-wrapper {
  margin-bottom: 1rem;
}

.placekey-field {
  width: 100%;
  padding: 0.5rem;
  border: 1px solid #e2e8f0;
  border-radius: 0.25rem;
}

.placekey-field-help {
  display: block;
  margin-top: 0.25rem;
  color: #718096;
  font-size: 0.875rem;
}

.placekey-coordinates-wrapper,
.placekey-address-wrapper {
  margin-bottom: 1rem;
}

.placekey-field-group {
  margin-bottom: 0.75rem;
}

.placekey-field-row {
  display: flex;
  gap: 0.5rem;
}

.placekey-field-row .placekey-field-group {
  flex: 1;
}

.placekey-preview-container {
  margin-top: 1rem;
  border: 1px solid #e2e8f0;
  border-radius: 0.25rem;
  overflow: hidden;
}

.placekey-preview-message {
  padding: 1rem;
  text-align: center;
  color: #718096;
}

.placekey-button-group {
  margin-top: 0.5rem;
}

.placekey-lookup-button {
  padding: 0.5rem 1rem;
  background-color: #4299e1;
  color: white;
  border: none;
  border-radius: 0.25rem;
  cursor: pointer;
}

.placekey-lookup-button:hover {
  background-color: #3182ce;
}

.placekey-lookup-button:disabled {
  background-color: #a0aec0;
  cursor: not-allowed;
}

/* Card styling */
.placekey-card {
  border: 1px solid #e2e8f0;
  border-radius: 0.25rem;
  padding: 1rem;
  margin-bottom: 1rem;
}

.placekey-card-title {
  margin-top: 0;
  margin-bottom: 0.5rem;
  font-size: 1.25rem;
}

.placekey-card-id {
  margin-bottom: 0.5rem;
  font-family: monospace;
}

.placekey-card-lat,
.placekey-card-lng {
  margin-bottom: 0.25rem;
  color: #718096;
}

.placekey-external-map-link {
  display: inline-block;
  margin-top: 0.5rem;
  color: #4299e1;
  text-decoration: none;
}

.placekey-external-map-link:hover {
  text-decoration: underline;
}
```
