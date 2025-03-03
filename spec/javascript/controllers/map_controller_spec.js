import { Application } from '@hotwired/stimulus'
import MapController from '../../../app/javascript/placekey_rails/controllers/map_controller'

describe('MapController', () => {
  let application
  let controller
  let element

  beforeEach(() => {
    // Set up a simple document body
    document.body.innerHTML = `
      <div data-controller="placekey-map"
           data-placekey-map-data-value='{"placekey":"@5vg-7gq-tvz","center":{"lat":37.7371,"lng":-122.44283},"boundary":[[37.7,-122.4],[37.7,-122.5],[37.8,-122.5],[37.8,-122.4],[37.75,-122.3],[37.7,-122.4]]}'
           data-placekey-map-zoom-value="15">
      </div>
    `
    
    // Mock Leaflet
    global.L = {
      map: jest.fn().mockReturnValue({
        setView: jest.fn().mockReturnThis(),
        remove: jest.fn()
      }),
      tileLayer: jest.fn().mockReturnValue({
        addTo: jest.fn()
      }),
      polygon: jest.fn().mockReturnValue({
        addTo: jest.fn(),
        getBounds: jest.fn(),
        bindPopup: jest.fn()
      }),
      marker: jest.fn().mockReturnValue({
        addTo: jest.fn(),
        bindPopup: jest.fn()
      })
    }
    
    // Initialize the Stimulus application
    application = Application.start()
    application.register('placekey-map', MapController)
    
    // Get the controller instance
    element = document.querySelector('[data-controller="placekey-map"]')
    controller = application.getControllerForElementAndIdentifier(element, 'placekey-map')
  })
  
  afterEach(() => {
    // Clean up
    document.body.innerHTML = ''
    delete global.L
  })
  
  describe('initialization', () => {
    it('initializes a map with the provided data', () => {
      expect(global.L.map).toHaveBeenCalledWith(element)
      expect(controller.map.setView).toHaveBeenCalledWith([37.7371, -122.44283], 15)
    })
    
    it('adds a tile layer to the map', () => {
      expect(global.L.tileLayer).toHaveBeenCalled()
      expect(controller.map.addTo).toHaveBeenCalled()
    })
    
    it('adds the hexagon boundary to the map', () => {
      expect(global.L.polygon).toHaveBeenCalled()
      expect(controller.hexagon.addTo).toHaveBeenCalled()
    })
    
    it('adds a marker at the center by default', () => {
      expect(global.L.marker).toHaveBeenCalledWith([37.7371, -122.44283])
      expect(controller.marker.addTo).toHaveBeenCalled()
    })
  })
  
  describe('configuration', () => {
    beforeEach(() => {
      document.body.innerHTML = `
        <div data-controller="placekey-map"
             data-placekey-map-data-value='{"placekey":"@5vg-7gq-tvz","center":{"lat":37.7371,"lng":-122.44283},"boundary":[[37.7,-122.4],[37.7,-122.5],[37.8,-122.5],[37.8,-122.4],[37.75,-122.3],[37.7,-122.4]]}'
             data-placekey-map-zoom-value="12"
             data-placekey-map-hexagon-color-value="#FF0000"
             data-placekey-map-hexagon-opacity-value="0.8"
             data-placekey-map-show-marker-value="false"
             data-placekey-map-fit-to-bounds-value="true">
        </div>
      `
      
      // Re-initialize controller with new configuration
      element = document.querySelector('[data-controller="placekey-map"]')
      controller = application.getControllerForElementAndIdentifier(element, 'placekey-map')
    })
    
    it('respects custom zoom level', () => {
      expect(controller.map.setView).toHaveBeenCalledWith([37.7371, -122.44283], 12)
    })
    
    it('applies custom hexagon styling', () => {
      expect(global.L.polygon).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({
          color: '#FF0000',
          fillOpacity: 0.8
        })
      )
    })
    
    it('does not add marker when configured not to', () => {
      expect(global.L.marker).not.toHaveBeenCalled()
    })
    
    it('fits map to bounds when configured', () => {
      expect(controller.hexagon.getBounds).toHaveBeenCalled()
    })
  })
  
  describe('error handling', () => {
    beforeEach(() => {
      // Set up with invalid data
      document.body.innerHTML = `
        <div data-controller="placekey-map"
             data-placekey-map-data-value='{"placekey":"@5vg-7gq-tvz"}'
             data-placekey-map-zoom-value="15">
        </div>
      `
      
      // Mock console.error
      console.error = jest.fn()
      
      // Re-initialize controller with invalid data
      element = document.querySelector('[data-controller="placekey-map"]')
      controller = application.getControllerForElementAndIdentifier(element, 'placekey-map')
    })
    
    it('logs an error when data is missing center property', () => {
      expect(console.error).toHaveBeenCalledWith(expect.stringContaining('missing or invalid'))
    })
    
    it('does not initialize map when data is invalid', () => {
      expect(global.L.map).not.toHaveBeenCalled()
    })
  })
  
  describe('cleanup', () => {
    it('removes the map when disconnected', () => {
      controller.disconnect()
      expect(controller.map.remove).toHaveBeenCalled()
    })
  })
})
