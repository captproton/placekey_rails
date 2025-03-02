require 'rails_helper'

RSpec.describe PlacekeyRails::Api::PlacekeysController, type: :routing do
  routes { PlacekeyRails::Engine.routes }

  describe "routing" do
    it "routes GET /api/placekeys/:id to #show" do
      expect(get: "/api/placekeys/123").to route_to(
        controller: "placekey_rails/api/placekeys",
        action: "show",
        id: "123"
      )
    end

    it "routes POST /api/placekeys/from_coordinates to #from_coordinates" do
      expect(post: "/api/placekeys/from_coordinates").to route_to(
        controller: "placekey_rails/api/placekeys",
        action: "from_coordinates"
      )
    end

    it "routes POST /api/placekeys/from_address to #from_address" do
      expect(post: "/api/placekeys/from_address").to route_to(
        controller: "placekey_rails/api/placekeys",
        action: "from_address"
      )
    end
  end
end
