module IntegrationTestHelper
  # Helper method to configure mocks for all PlacekeyRails module functions
  # that would otherwise hit the real API or require heavy computation
  def mock_placekey_module
    allow(PlacekeyRails).to receive(:geo_to_placekey) do |lat, lng|
      "@#{lat.to_i}-#{lng.to_i}-xyz"
    end
    
    allow(PlacekeyRails).to receive(:placekey_to_geo) do |placekey|
      parts = placekey.gsub('@', '').split('-')
      [parts[0].to_f, -parts[1].to_f]
    end
    
    allow(PlacekeyRails).to receive(:placekey_format_is_valid).and_return(true)
    allow(PlacekeyRails).to receive(:placekey_to_h3).and_return("8a2830828767fff")
    allow(PlacekeyRails).to receive(:h3_to_placekey).and_return("@5vg-7gq-tvz")
    allow(PlacekeyRails).to receive(:get_neighboring_placekeys).and_return(["@5vg-7gq-tvz", "@5vg-7gq-tvy"])
    allow(PlacekeyRails).to receive(:placekey_distance).and_return(123.45)
    allow(PlacekeyRails).to receive(:placekey_to_hex_boundary).and_return([[37.7, -122.4], [37.7, -122.5]])
    allow(PlacekeyRails).to receive(:placekey_to_geojson).and_return({"type" => "Polygon"})
  end
  
  # Helper method to mock the PlacekeyRails API client
  def mock_placekey_api_client
    api_client = instance_double(PlacekeyRails::Client)
    allow(PlacekeyRails).to receive(:default_client).and_return(api_client)
    
    allow(api_client).to receive(:lookup_placekey) do |params|
      lat = params[:latitude]
      lng = params[:longitude]
      
      {
        "placekey" => "@#{lat.to_i}-#{lng.to_i}-xyz",
        "query_id" => "test_#{lat}_#{lng}"
      }
    end
    
    allow(api_client).to receive(:lookup_placekeys) do |places|
      places.map do |place|
        lat = place[:latitude]
        lng = place[:longitude]
        
        {
          "placekey" => "@#{lat.to_i}-#{lng.to_i}-xyz",
          "query_id" => place[:query_id] || "test_#{lat}_#{lng}"
        }
      end
    end
    
    api_client
  end
  
  # Helper to create test locations
  def create_test_locations(count = 3, base_lat = 37.7749, base_lng = -122.4194)
    locations = []
    count.times do |i|
      locations << Location.create!(
        name: "Test Location #{i}",
        latitude: base_lat + (i * 0.01),
        longitude: base_lng - (i * 0.01)
      )
    end
    locations
  end
end

RSpec.configure do |config|
  config.include IntegrationTestHelper, type: :integration
  config.include IntegrationTestHelper, type: :system
end
