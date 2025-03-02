require 'rails_helper'

RSpec.describe PlacekeyRails::Api::PlacekeysController, type: :controller do
  routes { PlacekeyRails::Engine.routes }

  let(:valid_placekey) { "@5vg-82n-kzz" }
  let(:invalid_placekey) { "invalid-format" }
  let(:valid_lat) { 37.7371 }
  let(:valid_lng) { -122.44283 }

  describe "GET #show" do
    it "returns placekey information for valid placekey" do
      get :show, params: { id: valid_placekey }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)

      expect(json["placekey"]).to eq(valid_placekey)
      expect(json["center"]).to be_present
      expect(json["center"]["lat"]).to be_within(0.001).of(valid_lat)
      expect(json["center"]["lng"]).to be_within(0.001).of(valid_lng)
      expect(json["boundary"]).to be_present
      expect(json["geojson"]).to be_present
    end

    it "returns an error for invalid placekey" do
      get :show, params: { id: invalid_placekey }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)

      expect(json["error"]).to include("Invalid Placekey format")
    end
  end

  describe "POST #from_coordinates" do
    it "generates a placekey from valid coordinates" do
      post :from_coordinates, params: { latitude: valid_lat, longitude: valid_lng }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)

      expect(json["placekey"]).to be_present
      expect(PlacekeyRails.placekey_format_is_valid(json["placekey"])).to be true
      expect(json["latitude"]).to eq(valid_lat)
      expect(json["longitude"]).to eq(valid_lng)
    end

    it "returns an error for invalid coordinates" do
      post :from_coordinates, params: { latitude: 200, longitude: 300 }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)

      expect(json["error"]).to include("Invalid coordinates")
    end

    it "returns an error for missing coordinates" do
      post :from_coordinates, params: { latitude: valid_lat }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)

      expect(json["error"]).to include("Invalid coordinates")
    end
  end

  describe "POST #from_address" do
    let(:api_response) do
      {
        "placekey" => valid_placekey,
        "query_id" => "123",
        "street_address" => "123 Main St",
        "city" => "San Francisco"
      }
    end

    context "when API client is configured" do
      before do
        allow(PlacekeyRails).to receive(:default_client).and_return(double)
        allow(PlacekeyRails).to receive(:lookup_placekey).and_return(api_response)
      end

      it "looks up a placekey from a valid address" do
        post :from_address, params: {
          street_address: "123 Main St",
          city: "San Francisco",
          region: "CA",
          postal_code: "94105"
        }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)

        expect(json["placekey"]).to eq(valid_placekey)
        expect(json["query_id"]).to eq("123")
        expect(json["source"]).to eq("api")
      end

      it "returns an error when API returns no placekey" do
        allow(PlacekeyRails).to receive(:lookup_placekey).and_return({})

        post :from_address, params: { street_address: "Invalid Address" }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)

        expect(json["error"]).to include("No Placekey found")
      end

      it "returns an error when API throws an exception" do
        allow(PlacekeyRails).to receive(:lookup_placekey).and_raise(StandardError.new("API Error"))

        post :from_address, params: { street_address: "123 Main St" }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)

        expect(json["error"]).to include("Error looking up Placekey")
      end
    end

    context "when API client is not configured" do
      before do
        allow(PlacekeyRails).to receive(:default_client).and_return(nil)
      end

      it "returns a service unavailable error" do
        post :from_address, params: { street_address: "123 Main St" }

        expect(response).to have_http_status(:service_unavailable)
        json = JSON.parse(response.body)

        expect(json["error"]).to include("API client not configured")
      end
    end
  end
end
