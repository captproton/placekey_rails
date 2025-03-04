# Recommended Screenshots for PlacekeyRails Documentation

The following screenshots would greatly enhance the documentation for PlacekeyRails. These should be captured from a sample application using the gem.

## 1. Basic Placekey Map Display

A screenshot showing a basic map with a Placekey hexagon displayed on it. This would be the result of using the `leaflet_map_for_placekey` helper.

File: `docs/images/basic_placekey_map.png`

## 2. Placekey Card Component

A screenshot showing the Placekey card component that includes the formatted Placekey, coordinates, and a small map. This would be the result of using the `placekey_card` helper.

File: `docs/images/placekey_card.png`

## 3. Placekey Form Field

A screenshot showing the Placekey form field with validation and the preview map. This would be the result of using the `placekey_field` helper.

File: `docs/images/placekey_form_field.png`

## 4. Placekey Coordinate Fields

A screenshot showing the coordinate fields that automatically generate a Placekey. This would be the result of using the `placekey_coordinate_fields` helper.

File: `docs/images/placekey_coordinate_fields.png`

## 5. Placekey Address Fields

A screenshot showing the address form fields with the Placekey lookup button. This would be the result of using the `placekey_address_fields` helper.

File: `docs/images/placekey_address_fields.png`

## 6. Multiple Placekeys Map

A screenshot showing multiple Placekey hexagons on a map, demonstrating spatial queries. This would be the result of using the `within_distance` or `near_coordinates` methods.

File: `docs/images/multiple_placekeys_map.png`

## How to Create These Screenshots

1. Set up a sample application using the gem
2. Implement examples of each component
3. Style the components appropriately (using the CSS from the VIEW_HELPERS.md document)
4. Take screenshots of each component in action
5. Crop and optimize the images for web display
6. Save them in the `docs/images/` directory with the specified filenames

## Usage in Documentation

These screenshots should be referenced in the documentation files using Markdown image syntax:

```markdown
![Placekey Map](images/basic_placekey_map.png)
```

or with HTML for more control over size:

```html
<img src="images/placekey_card.png" alt="Placekey Card" width="500" />
```

The screenshots should be placed in context within the documentation where the related features are discussed to provide visual reference for users implementing these features.
