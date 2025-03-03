import { Controller } from "@hotwired/stimulus"

/**
 * Placekey Generator Controller
 * 
 * A Stimulus controller that automatically generates a Placekey from latitude/longitude inputs
 * 
 * Usage:
 * <div data-controller="placekey-generator"
 *      data-placekey-generator-lat-field-value="latitude"
 *      data-placekey-generator-lng-field-value="longitude"
 *      data-placekey-generator-placekey-field-value="placekey">
 * </div>
 */
export default class extends Controller {
  static values = {
    latField: String,
    lngField: String,
    placekeyField: String,
    debounce: { type: Number, default: 500 },
    apiPath: { type: String, default: "/placekey_rails/api/placekeys/from_coordinates" }
  }

  connect() {
    this.latField = document.querySelector(`[name="${this.latFieldValue}"]`);
    this.lngField = document.querySelector(`[name="${this.lngFieldValue}"]`);
    this.placekeyField = document.querySelector(`[name="${this.placekeyFieldValue}"]`);
    
    if (!this.latField || !this.lngField || !this.placekeyField) {
      console.error("Could not find all required fields for Placekey generator");
      return;
    }
    
    this.setupListeners();
  }
  
  setupListeners() {
    this.latField.addEventListener("change", this.debouncedGeneratePlacekey.bind(this));
    this.latField.addEventListener("blur", this.debouncedGeneratePlacekey.bind(this));
    
    this.lngField.addEventListener("change", this.debouncedGeneratePlacekey.bind(this));
    this.lngField.addEventListener("blur", this.debouncedGeneratePlacekey.bind(this));
    
    // If we already have coordinates but no placekey, generate one immediately
    if (this.hasValidCoordinates() && !this.placekeyField.value) {
      this.generatePlacekey();
    }
  }

  debouncedGeneratePlacekey() {
    clearTimeout(this.debounceTimer);
    this.debounceTimer = setTimeout(() => {
      this.generatePlacekey();
    }, this.debounceValue);
  }
  
  hasValidCoordinates() {
    const lat = parseFloat(this.latField.value);
    const lng = parseFloat(this.lngField.value);
    
    return !isNaN(lat) && !isNaN(lng) &&
           lat >= -90 && lat <= 90 &&
           lng >= -180 && lng <= 180;
  }
  
  /**
   * Generate a Placekey from the coordinates
   * This can work in two ways:
   * 1. If using the API client, makes an AJAX request
   * 2. If client-side, calculates directly (requires additional JS lib)
   */
  generatePlacekey() {
    if (!this.hasValidCoordinates()) {
      return;
    }
    
    const lat = parseFloat(this.latField.value);
    const lng = parseFloat(this.lngField.value);
    
    // Method 1: Use Rails API endpoint (preferred method)
    fetch(this.apiPathValue, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.getCSRFToken()
      },
      body: JSON.stringify({ latitude: lat, longitude: lng })
    })
    .then(response => response.json())
    .then(data => {
      if (data.placekey) {
        this.placekeyField.value = data.placekey;
        this.placekeyField.dispatchEvent(new Event('change'));
      }
    })
    .catch(error => {
      console.error("Error generating Placekey:", error);
    });
  }
  
  getCSRFToken() {
    const metaTag = document.querySelector('meta[name="csrf-token"]');
    return metaTag ? metaTag.content : '';
  }
}
