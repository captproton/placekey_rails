import { Controller } from "@hotwired/stimulus"

/**
 * Placekey Preview Controller
 * 
 * A Stimulus controller that shows a preview map for a Placekey field
 * 
 * Usage:
 * <div data-controller="placekey-preview"
 *      data-placekey-preview-target-value="preview-container-id"
 *      data-placekey-preview-field-value="placekey_field_name">
 * </div>
 */
export default class extends Controller {
  static values = {
    target: String,
    field: String,
    height: { type: String, default: "200px" },
    apiPath: { type: String, default: "/placekey_rails/api/placekeys/" }
  }

  connect() {
    this.field = document.querySelector(`[name="${this.fieldValue}"]`);
    this.targetElement = document.getElementById(this.targetValue);
    
    if (!this.field) {
      console.error("Could not find Placekey field for preview");
      return;
    }
    
    // Set up the preview container
    this.setupPreviewContainer();
    
    // Add event listeners
    this.field.addEventListener("change", this.updatePreview.bind(this));
    this.field.addEventListener("input", this.debouncedUpdatePreview.bind(this));
    
    // If field already has a value, show preview
    if (this.field.value) {
      this.updatePreview();
    }
  }
  
  setupPreviewContainer() {
    if (!this.targetElement) {
      // If target doesn't exist, create it
      this.targetElement = document.createElement('div');
      this.targetElement.id = this.targetValue;
      this.targetElement.className = 'placekey-preview-container';
      this.element.appendChild(this.targetElement);
    }
    
    this.targetElement.style.height = this.heightValue;
    this.targetElement.style.width = "100%";
    this.targetElement.style.display = "none"; // Hide initially
    
    // Create a message element
    this.messageElement = document.createElement('div');
    this.messageElement.className = 'placekey-preview-message';
    this.targetElement.appendChild(this.messageElement);
    
    // Create a map container
    this.mapContainer = document.createElement('div');
    this.mapContainer.className = 'placekey-preview-map';
    this.mapContainer.style.height = "100%";
    this.mapContainer.style.width = "100%";
    this.targetElement.appendChild(this.mapContainer);
  }
  
  debouncedUpdatePreview() {
    clearTimeout(this.debounceTimer);
    this.debounceTimer = setTimeout(() => {
      this.updatePreview();
    }, 500);
  }
  
  updatePreview() {
    const placekey = this.field.value;
    
    if (!placekey) {
      this.showMessage("Enter a Placekey to see a preview");
      return;
    }
    
    // Check if it matches the Placekey pattern
    const placekeyPattern = /^(@[23456789bcdfghjkmnpqrstvwxyzeu]{3}-[23456789bcdfghjkmnpqrstvwxyzeu]{3}-[23456789bcdfghjkmnpqrstvwxyzeu]{3}|[23456789bcdfghjkmnpqrstvwxyz]+-[23456789bcdfghjkmnpqrstvwxyz]+@[23456789bcdfghjkmnpqrstvwxyzeu]{3}-[23456789bcdfghjkmnpqrstvwxyzeu]{3}-[23456789bcdfghjkmnpqrstvwxyzeu]{3})$/;
    
    if (!placekeyPattern.test(placekey)) {
      this.showMessage("Invalid Placekey format");
      return;
    }
    
    // Fetch placekey data from API
    this.showMessage("Loading Placekey data...");
    
    fetch(`${this.apiPathValue}${encodeURIComponent(placekey)}`)
      .then(response => {
        if (!response.ok) {
          throw new Error(`HTTP error ${response.status}`);
        }
        return response.json();
      })
      .then(data => {
        if (data.error) {
          throw new Error(data.error);
        }
        this.renderMap(data);
      })
      .catch(error => {
        this.showMessage(`Error: ${error.message}`);
      });
  }
  
  showMessage(message) {
    // Hide the map and show the message
    this.targetElement.style.display = "block";
    this.mapContainer.style.display = "none";
    this.messageElement.style.display = "block";
    this.messageElement.textContent = message;
    
    // If we have a map, destroy it
    if (this.map) {
      this.map.remove();
      this.map = null;
    }
  }
  
  renderMap(data) {
    // If Leaflet is not available, show a message
    if (typeof L === 'undefined') {
      this.showMessage("Leaflet.js is required for map preview");
      return;
    }
    
    // Show the map container and hide the message
    this.targetElement.style.display = "block";
    this.mapContainer.style.display = "block";
    this.messageElement.style.display = "none";
    
    // If we already have a map, destroy it
    if (this.map) {
      this.map.remove();
    }
    
    // Create a new map
    this.map = L.map(this.mapContainer).setView([data.center.lat, data.center.lng], 15);
    
    // Add the tile layer
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap contributors'
    }).addTo(this.map);
    
    // Add the hexagon boundary
    if (data.boundary) {
      const hexagonCoords = data.boundary.map(coord => [coord[1], coord[0]]);
      L.polygon(hexagonCoords, {
        color: '#3388ff',
        fillColor: '#3388ff',
        fillOpacity: 0.4,
        weight: 2
      }).addTo(this.map);
    }
    
    // Add a marker at the center
    L.marker([data.center.lat, data.center.lng])
      .addTo(this.map)
      .bindPopup(`Placekey: ${data.placekey}`);
  }
  
  disconnect() {
    // Clean up event listeners
    if (this.field) {
      this.field.removeEventListener("change", this.updatePreview.bind(this));
      this.field.removeEventListener("input", this.debouncedUpdatePreview.bind(this));
    }
    
    // Clean up map
    if (this.map) {
      this.map.remove();
      this.map = null;
    }
  }
}
