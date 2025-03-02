require 'rails_helper'

RSpec.describe PlacekeyRails::Api::PlacekeysController, type: :controller do
  routes { PlacekeyRails::Engine.routes }
  
  before do
    # Mock the PlacekeyRails module methods
    allow(PlacekeyRails).to receive(:placekey_format_is_valid).with('@5vg-7gq-tvz').and_return(true)
    allow(PlacekeyRails).to receive(:placekey_format_is_valid).with('invalid-format').and_return(false)
    allow(PlacekeyRails).to receive(:placekey_to_geo).with('@5vg-7gq-tvz').and_return([37.7371, -122.44283])
    allow(PlacekeyRails).to receive(:placekey_to_hex_boundary).and_return([[37.7, -122.4], [37.7, -122.5]])
    allow(PlacekeyRails).to receive(:placekey_to_geojson).and_return({ "type" => "Polygon" })
    allow(PlacekeyRails).to receive(:geo_to_placekey).with(any_args).and_return('@5vg-7gq-tvz')
    allow(PlacekeyRails).to receive(:default_client).and_return(double('client'))
    allow(PlacekeyRails).to receive(:lookup_placekey).and_return({
      "placekey" => "@5vg-7gq-tvz",
      "query_id" => "test123"
    })
  end

  describe 'GET #show' do
    it 'returns placekey information for a valid placekey' do
      get :show, params: { id: '@5vg-7gq-tvz' }
      
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['placekey']).to eq('@5vg-7gq-tvz')
      expect(json_response['center']).to be_present
      expect(json_response['boundary']).to be_present
      expect(json_response['geojson']).to be_present
    end
    
    it 'returns error for invalid placekey format' do
      get :show, params: { id: 'invalid-format' }
      
      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to be_present
    end
    
    it 'handles errors gracefully' do
      allow(PlacekeyRails).to receive(:placekey_to_geo).and_raise(StandardError.new("Test error"))
      
      get :show, params: { id: '@5vg-7gq-tvz' }
      
      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to include("Test error")
    end
  end
  
  describe 'POST #from_coordinates' do
    it 'generates placekey from valid coordinates' do
      post :from_coordinates, params: { latitude: 37.7371, longitude: -122.44283 }
      
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['placekey']).to eq('@5vg-7gq-tvz')
      expect(json_response['latitude']).to eq(37.7371)
      expect(json_response['longitude']).to eq(-122.44283)
    end
    
    it 'returns error for invalid coordinates' do
      # Mock validation to fail
      allow(controller).to receive(:valid_coordinates?).and_return(false)
      
      post :from_coordinates, params: { latitude: 'invalid', longitude: -122.44283 }
      
      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('Invalid coordinates')
    end
    
    it 'returns error for out-of-range coordinates' do
      allow(controller).to receive(:valid_coordinates?).and_return(false)
      
      post :from_coordinates, params: { latitude: 100, longitude: -122.44283 }
      
      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('Invalid coordinates')
    end
    
    it 'handles errors gracefully' do
      allow(PlacekeyRails).to receive(:geo_to_placekey).and_raise(StandardError.new("Test error"))
      
      post :from_coordinates, params: { latitude: 37.7371, longitude: -122.44283 }
      
      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to include("Test error")
    end
  end
  
  describe 'POST #from_address' do
    it 'looks up placekey from address' do
      post :from_address, params: { 
        street_address: '598 Portola Dr',
        city: 'San Francisco',
        region: 'CA',
        postal_code: '94131'
      }
      
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['placekey']).to eq('@5vg-7gq-tvz')
      expect(json_response['query_id']).to eq('test123')
    end
    
    it 'returns error when API client not configured' do
      allow(PlacekeyRails).to receive(:default_client).and_return(nil)
      
      post :from_address, params: { street_address: '598 Portola Dr' }
      
      expect(response).to have_http_status(:service_unavailable)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('Placekey API client not configured')
    end
    
    it 'returns not found when no placekey is found' do
      allow(PlacekeyRails).to receive(:lookup_placekey).and_return({ "error" => "No match found" })
      
      post :from_address, params: { street_address: 'Unknown Address' }
      
      expect(response).to have_http_status(:not_found)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('No Placekey found for this address')
    end
    
    it 'handles errors gracefully' do
      allow(PlacekeyRails).to receive(:lookup_placekey).and_raise(StandardError.new("Test error"))
      
      post :from_address, params: { street_address: '598 Portola Dr' }
      
      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to include("Test error")
    end
  end
end
