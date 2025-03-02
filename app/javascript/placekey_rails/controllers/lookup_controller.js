import { Controller } from "@hotwired/stimulus"

/**
 * Placekey Lookup Controller
 * 
 * A Stimulus controller that looks up a Placekey from address components
 * 
 * Usage:
 * <div data-controller="placekey-lookup"
 *      data-placekey-lookup-address-field-value="street_address"
 *      data-placekey-lookup-city-field-value="city"
 *      ...>
 * </div>
 */
export default class extends Controller {
  static values = {
    id: String,
    addressField: String,
    cityField: String,
    regionField: String,
    postalCodeField: String,
    countryField: String,
    placekeyField: String,
    apiPath: { type: String, default: "/placekey_rails/api/placekeys/from_address" }
  }

  connect() {
    this.addressField = document.querySelector(`[name="${this.addressFieldValue}"]`);
    this.cityField = document.querySelector(`[name="${this.cityFieldValue}"]`);
    this.regionField = document.querySelector(`[name="${this.regionFieldValue}"]`);
    this.postalCodeField = document.querySelector(`[name="${this.postalCodeFieldValue}"]`);
    this.countryField = document.querySelector(`[name="${this.countryFieldValue}"]`);
    this.placekeyField = document.querySelector(`[name="${this.placekeyFieldValue}"]`);
    
    // Verify we have the required fields
    if (!this.addressField || !this.placekeyField) {
      console.error("Could not find all required fields for Placekey lookup");
      return;
    }
  }
  
  lookup() {
    if (!this.addressField.value) {
      alert("Please enter a street address to lookup a Placekey.");
      return;
    }
    
    // Prepare address data
    const addressData = {
      street_address: this.addressField.value
    };
    
    // Add optional fields if present
    if (this.cityField && this.cityField.value) {
      addressData.city = this.cityField.value;
    }
    
    if (this.regionField && this.regionField.value) {
      addressData.region = this.regionField.value;
    }
    
    if (this.postalCodeField && this.postalCodeField.value) {
      addressData.postal_code = this.postalCodeField.value;
    }
    
    if (this.countryField && this.countryField.value) {
      addressData.iso_country_code = this.countryField.value;
    }
    
    // Show loading state
    this.setLoadingState(true);
    
    // Make API request
    fetch(this.apiPathValue, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.getCSRFToken()
      },
      body: JSON.stringify(addressData)
    })
    .then(response => response.json())
    .then(data => {
      if (data.placekey) {
        this.placekeyField.value = data.placekey;
        this.placekeyField.dispatchEvent(new Event('change'));
      } else if (data.error) {
        alert(`Error looking up Placekey: ${data.error}`);
      } else {
        alert("No Placekey found for this address. Please verify the address is correct.");
      }
    })
    .catch(error => {
      console.error("Error looking up Placekey:", error);
      alert("Error looking up Placekey. Please try again later.");
    })
    .finally(() => {
      this.setLoadingState(false);
    });
  }
  
  setLoadingState(isLoading) {
    const lookupButton = document.querySelector('.placekey-lookup-button');
    if (lookupButton) {
      if (isLoading) {
        lookupButton.setAttribute('disabled', 'disabled');
        lookupButton.innerHTML = 'Looking up...';
      } else {
        lookupButton.removeAttribute('disabled');
        lookupButton.innerHTML = 'Lookup Placekey';
      }
    }
  }
  
  getCSRFToken() {
    const metaTag = document.querySelector('meta[name="csrf-token"]');
    return metaTag ? metaTag.content : '';
  }
}
