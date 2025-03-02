import { Controller } from "@hotwired/stimulus"

/**
 * Placekey Map Controller
 * 
 * A Stimulus controller for displaying Placekey hexagons on a map.
 * Requires Leaflet.js to be included in your application.
 * 
 * Usage:
 * <div data-controller="placekey-map"
 *      data-placekey-map-data-value='{"placekey":"@5vg-7gq-tvz","center":{"lat":37.7371,"lng":-122.44283},...}'
 *      data-placekey-map-zoom-value="15">
 * </div>
 */
export default class extends Controller {
  static values = {
    data: Object,
    zoom: { type: Number, default: 15 },
    tileUrl: { type: String, default: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" },
    attribution: { type: String, default: "&copy; OpenStreetMap contributors" },
    hexagonColor: { type: String, default: "#3388ff" },
    hexagonFillColor: { type: String, default: "#3388ff" },
    hexagonOpacity: { type: Number, default: 0.4 },
    hexagonWeight: { type: Number, default: 2 },
    showMarker: { type: Boolean, default: true },
    fitToBounds: { type: Boolean, default: false }
  }

  connect() {
    if (!this.hasDataValue || !this.dataValue.center) {
      console.error("Placekey map data is missing or invalid.");
      return;
    }

    this.initializeMap();
    this.addTileLayer();
    this.addHexagon();
    
    if (this.showMarkerValue) {
      this.addMarker();
    }
  }

  initializeMap() {
    // If Leaflet is not available, log an error
    if (typeof L === 'undefined') {
      console.error("Leaflet is not available. Make sure to include Leaflet in your application.");
      return;
    }

    const center = [this.dataValue.center.lat, this.dataValue.center.lng];
    this.map = L.map(this.element).setView(center, this.zoomValue);
  }

  addTileLayer() {
    if (!this.map) return;

    L.tileLayer(this.tileUrlValue, {
      attribution: this.attributionValue
    }).addTo(this.map);
  }

  addHexagon() {
    if (!this.map || !this.dataValue.boundary) return;
    
    // Convert boundary to Leaflet format
    const hexagonCoords = this.dataValue.boundary.map(coord => [coord[1], coord[0]]);
    
    this.hexagon = L.polygon(hexagonCoords, {
      color: this.hexagonColorValue,
      fillColor: this.hexagonFillColorValue,
      fillOpacity: this.hexagonOpacityValue,
      weight: this.hexagonWeightValue
    }).addTo(this.map);
    
    if (this.fitToBoundsValue) {
      this.map.fitBounds(this.hexagon.getBounds());
    }
    
    // Add a popup with the placekey
    if (this.dataValue.placekey) {
      this.hexagon.bindPopup(`Placekey: ${this.dataValue.placekey}`);
    }
  }

  addMarker() {
    if (!this.map || !this.dataValue.center) return;
    
    const center = [this.dataValue.center.lat, this.dataValue.center.lng];
    this.marker = L.marker(center).addTo(this.map);
    
    if (this.dataValue.placekey) {
      this.marker.bindPopup(`Placekey: ${this.dataValue.placekey}`);
    }
  }

  disconnect() {
    if (this.map) {
      this.map.remove();
      this.map = null;
    }
  }
}
