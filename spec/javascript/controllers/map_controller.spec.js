/**
 * @jest-environment jsdom
 */

import { Application } from '@hotwired/stimulus';
import MapController from '../../../app/javascript/placekey_rails/controllers/map_controller';

// Mock Leaflet globally
global.L = {
  map: jest.fn().mockReturnValue({
    setView: jest.fn().mockReturnThis(),
    remove: jest.fn(),
    fitBounds: jest.fn()
  }),
  tileLayer: jest.fn().mockReturnValue({
    addTo: jest.fn().mockReturnThis()
  }),
  polygon: jest.fn().mockReturnValue({
    addTo: jest.fn().mockReturnThis(),
    bindPopup: jest.fn().mockReturnThis(),
    getBounds: jest.fn().mockReturnValue({})
  }),
  marker: jest.fn().mockReturnValue({
    addTo: jest.fn().mockReturnThis(),
    bindPopup: jest.fn().mockReturnThis()
  })
};

describe('MapController', () => {
  let application;
  let controller;
  let element;
  
  const sampleData = {
    placekey: '@5vg-82n-kzz',
    center: { lat: 37.7371, lng: -122.44283 },
    boundary: [
      [-122.443, 37.775],
      [-122.441, 37.774],
      [-122.439, 37.772],
      [-122.441, 37.770],
      [-122.443, 37.770],
      [-122.445, 37.772]
    ]
  };
  
  beforeEach(() => {
    // Set up DOM element
    document.body.innerHTML = '<div data-controller="placekey-map"></div>';
    element = document.querySelector('div');
    
    // Set up Stimulus application and controller
    application = Application.start();
    application.register('placekey-map', MapController);
    
    // Set data values
    element.dataset.placekeyMapDataValue = JSON.stringify(sampleData);
    element.dataset.placekeyMapZoomValue = '15';
    element.dataset.placekeyMapHexagonColorValue = '#3388ff';
    element.dataset.placekeyMapShowMarkerValue = 'true';
  });
  
  afterEach(() => {
    document.body.innerHTML = '';
    jest.clearAllMocks();
  });
  
  it('initializes the map on connect', () => {
    // This will connect the controller
    controller = application.getControllerForElementAndIdentifier(element, 'placekey-map');
    
    // Verify map was initialized
    expect(global.L.map).toHaveBeenCalledWith(element);
    expect(global.L.map().setView).toHaveBeenCalledWith([37.7371, -122.44283], 15);
  });
  
  it('adds a tile layer to the map', () => {
    controller = application.getControllerForElementAndIdentifier(element, 'placekey-map');
    
    expect(global.L.tileLayer).toHaveBeenCalled();
    expect(global.L.tileLayer().addTo).toHaveBeenCalled();
  });
  
  it('adds a hexagon polygon to the map', () => {
    controller = application.getControllerForElementAndIdentifier(element, 'placekey-map');
    
    expect(global.L.polygon).toHaveBeenCalled();
    expect(global.L.polygon().addTo).toHaveBeenCalled();
  });
  
  it('adds a marker to the map when showMarker is true', () => {
    controller = application.getControllerForElementAndIdentifier(element, 'placekey-map');
    
    expect(global.L.marker).toHaveBeenCalledWith([37.7371, -122.44283]);
    expect(global.L.marker().addTo).toHaveBeenCalled();
    expect(global.L.marker().bindPopup).toHaveBeenCalledWith('Placekey: @5vg-82n-kzz');
  });
  
  it('does not add a marker when showMarker is false', () => {
    element.dataset.placekeyMapShowMarkerValue = 'false';
    controller = application.getControllerForElementAndIdentifier(element, 'placekey-map');
    
    expect(global.L.marker).not.toHaveBeenCalled();
  });
  
  it('fits bounds when fitToBounds is true', () => {
    element.dataset.placekeyMapFitToBoundsValue = 'true';
    controller = application.getControllerForElementAndIdentifier(element, 'placekey-map');
    
    expect(global.L.map().fitBounds).toHaveBeenCalled();
  });
  
  it('cleans up the map on disconnect', () => {
    controller = application.getControllerForElementAndIdentifier(element, 'placekey-map');
    controller.disconnect();
    
    expect(global.L.map().remove).toHaveBeenCalled();
  });
  
  it('handles missing data gracefully', () => {
    // Clear the data values
    delete element.dataset.placekeyMapDataValue;
    
    // Create a spy on console.error
    jest.spyOn(console, 'error').mockImplementation(() => {});
    
    controller = application.getControllerForElementAndIdentifier(element, 'placekey-map');
    
    expect(console.error).toHaveBeenCalled();
    expect(console.error).toHaveBeenCalledWith('Placekey map data is missing or invalid.');
    
    // Restore console.error
    console.error.mockRestore();
  });
});
