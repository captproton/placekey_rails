# JavaScript Components

PlacekeyRails includes several JavaScript components built with Stimulus.js to enhance the user experience when working with Placekeys.

## Table of Contents

- [Setup](#setup)
- [Map Controller](#map-controller)
- [Generator Controller](#generator-controller)
- [Lookup Controller](#lookup-controller)
- [Preview Controller](#preview-controller)
- [API Integration](#api-integration)

## Setup

### Installation

The JavaScript components are automatically included when you use the gem. They require:

1. Stimulus.js (part of Rails 7+ by default)
2. Leaflet.js (for map visualization)

Include Leaflet in your application's layout or package:

```html
<!-- In your layout -->
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
```

Or install via npm/yarn:

```bash
yarn add leaflet
```

And import in your JavaScript:

```javascript
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
```

### Importing PlacekeyRails JavaScript

In your application's JavaScript entry point:

```javascript
// app/javascript/application.js
import "placekey_rails"
```

If you're using esbuild or webpack:

```javascript
import "placekey_rails"
```

## Map Controller

The Map Controller displays a Placekey hexagon on a Leaflet map.

### Basic Usage

```html
<div data-controller="placekey-map"
     data-placekey-map-data-value='{"placekey":"@5vg-7gq-tvz","center":{"lat":37.7371,"lng":-122.44283},"boundary":[[-122.443,37.775],...]}'
     data-placekey-map-zoom-value="15"
     style="height: 400px; width: 100%;">
</div>
```

### Options

Configure the map with data attributes:

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `data-placekey-map-data-value` | Object | - | Map data object with placekey, center, and boundary |
| `data-placekey-map-zoom-value` | Number | 15 | Initial zoom level |
| `data-placekey-map-tile-url-value` | String | OpenStreetMap URL | Tile layer URL template |
| `data-placekey-map-attribution-value` | String | OSM attribution | Map attribution text |
| `data-placekey-map-hexagon-color-value` | String | "#3388ff" | Hexagon border color |
| `data-placekey-map-hexagon-fill-color-value` | String | "#3388ff" | Hexagon fill color |
| `data-placekey-map-hexagon-opacity-value` | Number | 0.4 | Hexagon fill opacity |
| `data-placekey-map-hexagon-weight-value` | Number | 2 | Hexagon border width |
| `data-placekey-map-show-marker-value` | Boolean | true | Whether to show a marker at the center |
| `data-placekey-map-fit-to-bounds-value` | Boolean | false | Whether to fit the map to the hexagon bounds |

### Example

```erb
<% map_data = placekey_map_data("@5vg-82n-kzz") %>

<div data-controller="placekey-map"
     data-placekey-map-data-value="<%= map_data.to_json %>"
     data-placekey-map-zoom-value="14"
     data-placekey-map-hexagon-color-value="#4299e1"
     data-placekey-map-fit-to-bounds-value="true"
     style="height: 400px; width: 100%;">
</div>
```

## Generator Controller

The Generator Controller automatically creates a Placekey from latitude and longitude inputs.

### Basic Usage

```html
<div data-controller="placekey-generator"
     data-placekey-generator-lat-field-value="location[latitude]"
     data-placekey-generator-lng-field-value="location[longitude]"
     data-placekey-generator-placekey-field-value="location[placekey]">
</div>
```

### Options

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `data-placekey-generator-lat-field-value` | String | - | Name of the latitude input field |
| `data-placekey-generator-lng-field-value` | String | - | Name of the longitude input field |
| `data-placekey-generator-placekey-field-value` | String | - | Name of the placekey input field |
| `data-placekey-generator-debounce-value` | Number | 500 | Debounce time in milliseconds |
| `data-placekey-generator-api-path-value` | String | "/placekey_rails/api/placekeys/from_coordinates" | API endpoint path |

### Example

```erb
<%= form_with(model: @location) do |form| %>
  <%= form.label :latitude %>
  <%= form.text_field :latitude, class: "coordinates-input" %>

  <%= form.label :longitude %>
  <%= form.text_field :longitude, class: "coordinates-input" %>

  <%= form.label :placekey %>
  <%= form.text_field :placekey, readonly: true %>

  <div data-controller="placekey-generator"
       data-placekey-generator-lat-field-value="location[latitude]"
       data-placekey-generator-lng-field-value="location[longitude]"
       data-placekey-generator-placekey-field-value="location[placekey]">
  </div>
<% end %>
```

## Lookup Controller

The Lookup Controller looks up a Placekey from address components using the Placekey API.

### Basic Usage

```html
<div data-controller="placekey-lookup"
     data-placekey-lookup-address-field-value="location[street_address]"
     data-placekey-lookup-city-field-value="location[city]"
     data-placekey-lookup-region-field-value="location[region]"
     data-placekey-lookup-postal-code-field-value="location[postal_code]"
     data-placekey-lookup-country-field-value="location[country]"
     data-placekey-lookup-placekey-field-value="location[placekey]">
</div>
```

### Options

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `data-placekey-lookup-address-field-value` | String | - | Name of the street address input field |
| `data-placekey-lookup-city-field-value` | String | - | Name of the city input field |
| `data-placekey-lookup-region-field-value` | String | - | Name of the region input field |
| `data-placekey-lookup-postal-code-field-value` | String | - | Name of the postal code input field |
| `data-placekey-lookup-country-field-value` | String | - | Name of the country input field |
| `data-placekey-lookup-placekey-field-value` | String | - | Name of the placekey input field |
| `data-placekey-lookup-api-path-value` | String | "/placekey_rails/api/placekeys/from_address" | API endpoint path |

### Example

```erb
<%= form_with(model: @location) do |form| %>
  <%= form.label :street_address %>
  <%= form.text_field :street_address %>

  <%= form.label :city %>
  <%= form.text_field :city %>

  <%= form.label :region %>
  <%= form.text_field :region %>

  <%= form.label :postal_code %>
  <%= form.text_field :postal_code %>

  <%= form.label :country %>
  <%= form.text_field :country %>

  <%= form.label :placekey %>
  <%= form.text_field :placekey %>

  <div data-controller="placekey-lookup"
       data-placekey-lookup-address-field-value="location[street_address]"
       data-placekey-lookup-city-field-value="location[city]"
       data-placekey-lookup-region-field-value="location[region]"
       data-placekey-lookup-postal-code-field-value="location[postal_code]"
       data-placekey-lookup-country-field-value="location[country]"
       data-placekey-lookup-placekey-field-value="location[placekey]">
  </div>

  <button type="button" data-action="placekey-lookup#lookup">
    Lookup Placekey
  </button>
<% end %>
```

## Preview Controller

The Preview Controller shows a map preview for a Placekey field.

### Basic Usage

```html
<div data-controller="placekey-preview"
     data-placekey-preview-target-value="preview-container-id"
     data-placekey-preview-field-value="location[placekey]">
</div>
<div id="preview-container-id" style="height: 200px;"></div>
```

### Options

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `data-placekey-preview-target-value` | String | - | ID of the preview container element |
| `data-placekey-preview-field-value` | String | - | Name of the placekey input field |
| `data-placekey-preview-height-value` | String | "200px" | Height of the preview container |
| `data-placekey-preview-api-path-value` | String | "/placekey_rails/api/placekeys/" | API endpoint path |

### Example

```erb
<%= form_with(model: @location) do |form| %>
  <%= form.label :placekey %>
  <%= form.text_field :placekey %>

  <div data-controller="placekey-preview"
       data-placekey-preview-target-value="placekey-preview"
       data-placekey-preview-field-value="location[placekey]"
       data-placekey-preview-height-value="250px">
  </div>
  <div id="placekey-preview" style="height: 250px; width: 100%;"></div>
<% end %>
```

## API Integration

### Required API Endpoints

The JavaScript components communicate with these Rails API endpoints:

1. `GET /placekey_rails/api/placekeys/:placekey` - Get information about a Placekey
2. `POST /placekey_rails/api/placekeys/from_coordinates` - Generate a Placekey from coordinates
3. `POST /placekey_rails/api/placekeys/from_address` - Look up a Placekey from an address

These endpoints are automatically provided by the PlacekeyRails engine.

### Authentication

The JavaScript components use Rails CSRF token authentication for API requests. Make sure your application includes the CSRF meta tag:

```erb
<%= csrf_meta_tags %>
```

### Cross-Origin Requests

If you're using the components from a different origin, configure CORS appropriately.

## Customization

### Overriding Controllers

You can create your own Stimulus controllers that extend the PlacekeyRails ones:

```javascript
// app/javascript/controllers/custom_placekey_map_controller.js
import { MapController } from "placekey_rails/controllers"

export default class extends MapController {
  connect() {
    super.connect()
    // Add your custom code here
    console.log("Custom map controller connected")
  }
  
  // Override methods as needed
  addMarker() {
    super.addMarker()
    // Customize the marker
    if (this.marker) {
      this.marker.setIcon(L.icon({
        iconUrl: '/custom-marker.png',
        iconSize: [25, 41],
        iconAnchor: [12, 41]
      }))
    }
  }
}
```

Register your custom controller:

```javascript
// app/javascript/controllers/index.js
import { application } from "controllers/application"
import CustomPlacekeyMapController from "./custom_placekey_map_controller"

application.register("custom-placekey-map", CustomPlacekeyMapController)
```

### Styling

The components include minimal styling. You can customize the appearance with CSS:

```css
/* Example: Custom map styles */
.placekey-preview-map .leaflet-control-zoom {
  border-radius: 4px;
  overflow: hidden;
}

/* Example: Custom form field styles */
.placekey-field {
  border: 2px solid #4299e1;
  border-radius: 4px;
  padding: 8px 12px;
  transition: border-color 0.3s;
}

.placekey-field:focus {
  border-color: #3182ce;
  outline: none;
  box-shadow: 0 0 0 3px rgba(66, 153, 225, 0.25);
}
```
