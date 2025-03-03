import { Application } from '@hotwired/stimulus'
import GeneratorController from '../../../app/javascript/placekey_rails/controllers/generator_controller'

describe('GeneratorController', () => {
  let application
  let controller
  let element
  let latField
  let lngField
  let placekeyField

  beforeEach(() => {
    // Set up DOM for testing
    document.body.innerHTML = `
      <div data-controller="placekey-generator"
           data-placekey-generator-lat-field-value="place[latitude]"
           data-placekey-generator-lng-field-value="place[longitude]"
           data-placekey-generator-placekey-field-value="place[placekey]">
      </div>
      <input id="place_latitude" name="place[latitude]" value="37.7371">
      <input id="place_longitude" name="place[longitude]" value="-122.44283">
      <input id="place_placekey" name="place[placekey]" value="">
    `
    
    // Set up elements
    element = document.querySelector('[data-controller="placekey-generator"]')
    latField = document.getElementById('place_latitude')
    lngField = document.getElementById('place_longitude')
    placekeyField = document.getElementById('place_placekey')
    
    // Mock fetch API
    global.fetch = jest.fn().mockImplementation(() => 
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve({ placekey: '@5vg-7gq-tvz' })
      })
    )
    
    // Initialize Stimulus application
    application = Application.start()
    application.register('placekey-generator', GeneratorController)
    
    // Get controller instance
    controller = application.getControllerForElementAndIdentifier(element, 'placekey-generator')
  })
  
  afterEach(() => {
    document.body.innerHTML = ''
    jest.resetAllMocks()
  })
  
  describe('initialization', () => {
    it('finds all required fields', () => {
      expect(controller.latField).toBe(latField)
      expect(controller.lngField).toBe(lngField)
      expect(controller.placekeyField).toBe(placekeyField)
    })
    
    it('sets up event listeners on coordinate fields', () => {
      const addEventListenerSpy = jest.spyOn(latField, 'addEventListener')
      controller.connect()
      expect(addEventListenerSpy).toHaveBeenCalledWith('change', expect.any(Function))
    })
  })
  
  describe('coordinate changes', () => {
    beforeEach(() => {
      // Reset placekey field
      placekeyField.value = ''
    })
    
    it('generates placekey when both coordinates are valid', async () => {
      // Trigger change event on latitude field
      latField.value = '37.7371'
      lngField.value = '-122.44283'
      latField.dispatchEvent(new Event('change'))
      
      // Wait for the async request to complete
      await new Promise(resolve => setTimeout(resolve, 0))
      
      expect(global.fetch).toHaveBeenCalledWith(
        expect.stringContaining('/placekey_rails/api/placekeys/from_coordinates'),
        expect.objectContaining({
          method: 'POST',
          body: expect.stringContaining('37.7371')
        })
      )
      
      expect(placekeyField.value).toBe('@5vg-7gq-tvz')
    })
    
    it('does not generate placekey when coordinates are incomplete', async () => {
      // Set latitude but not longitude
      latField.value = '37.7371'
      lngField.value = ''
      latField.dispatchEvent(new Event('change'))
      
      // Wait for any potential async operations
      await new Promise(resolve => setTimeout(resolve, 0))
      
      expect(global.fetch).not.toHaveBeenCalled()
      expect(placekeyField.value).toBe('')
    })
    
    it('does not overwrite existing placekey value', async () => {
      // Set existing placekey
      placekeyField.value = '@existing-value'
      
      // Trigger change
      latField.value = '37.7371'
      lngField.value = '-122.44283'
      latField.dispatchEvent(new Event('change'))
      
      // Wait for any potential async operations
      await new Promise(resolve => setTimeout(resolve, 0))
      
      expect(global.fetch).not.toHaveBeenCalled()
      expect(placekeyField.value).toBe('@existing-value')
    })
  })
  
  describe('error handling', () => {
    beforeEach(() => {
      // Mock fetch to return an error
      global.fetch = jest.fn().mockImplementation(() => 
        Promise.resolve({
          ok: false,
          json: () => Promise.resolve({ error: 'Invalid coordinates' })
        })
      )
      
      // Mock console.error
      console.error = jest.fn()
    })
    
    it('handles API errors gracefully', async () => {
      latField.value = '37.7371'
      lngField.value = '-122.44283'
      latField.dispatchEvent(new Event('change'))
      
      // Wait for the async request to complete
      await new Promise(resolve => setTimeout(resolve, 0))
      
      expect(console.error).toHaveBeenCalledWith(expect.stringContaining('Error generating Placekey'))
      expect(placekeyField.value).toBe('')
    })
    
    it('handles network errors gracefully', async () => {
      global.fetch = jest.fn().mockImplementation(() => 
        Promise.reject(new Error('Network error'))
      )
      
      latField.value = '37.7371'
      lngField.value = '-122.44283'
      latField.dispatchEvent(new Event('change'))
      
      // Wait for the async request to complete
      await new Promise(resolve => setTimeout(resolve, 0))
      
      expect(console.error).toHaveBeenCalledWith(expect.stringContaining('Network error'))
      expect(placekeyField.value).toBe('')
    })
  })
})
