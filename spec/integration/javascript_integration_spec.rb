require 'rails_helper'

RSpec.describe "JavaScript Component Integration", type: :system, js: true do
  # These tests require a JavaScript-capable driver like Selenium
  # If the system tests are not properly configured, these will be skipped
  
  before do
    # Skip these tests if the JS testing environment is not available
    skip "JavaScript system tests not configured" unless ENV['ENABLE_JS_TESTS']
    
    # Configure PlacekeyRails modules
    allow(PlacekeyRails).to receive(:geo_to_placekey) do |lat, lng|
      "@#{lat.to_i}-#{lng.to_i}-xyz"
    end
    
    allow(PlacekeyRails).to receive(:placekey_to_geo) do |placekey|
      parts = placekey.gsub('@', '').split('-')
      [parts[0].to_f, -parts[1].to_f]
    end
    
    # Create test data
    Location.destroy_all
    @location = Location.create!(
      name: "Test Location",
      latitude: 37.7749,
      longitude: -122.4194
    )
  end
  
  describe "Generator controller" do
    it "generates placekey when coordinates are entered" do
      visit new_location_path
      
      # Enter coordinates
      fill_in "location[latitude]", with: "37.7749"
      fill_in "location[longitude]", with: "-122.4194"
      
      # Let the JS execute
      sleep 0.5
      
      # Check if placekey field was automatically populated
      expect(find_field("location[placekey]").value).not_to be_empty
    end
    
    it "clears placekey when coordinates are cleared" do
      visit edit_location_path(@location)
      
      # Clear coordinates
      fill_in "location[latitude]", with: ""
      fill_in "location[longitude]", with: ""
      
      # Let the JS execute
      sleep 0.5
      
      # Placekey should be cleared
      expect(find_field("location[placekey]").value).to be_empty
    end
    
    it "validates coordinates before generating placekey" do
      visit new_location_path
      
      # Enter invalid coordinates
      fill_in "location[latitude]", with: "100"  # Out of range
      fill_in "location[longitude]", with: "-122.4194"
      
      # Let the JS execute
      sleep 0.5
      
      # Should show validation error
      expect(page).to have_css(".placekey-error")
    end
  end
  
  describe "Map controller" do
    it "displays locations on the map" do
      # Create multiple locations for the map
      Location.create!(
        name: "Location 2",
        latitude: 37.8,
        longitude: -122.5
      )
      
      visit locations_path
      
      # The map should be rendered
      expect(page).to have_css(".placekey-map")
      
      # Map should have markers
      expect(page).to have_css(".placekey-map-marker")
    end
    
    it "shows location info in a popup when marker is clicked" do
      visit location_path(@location)
      
      # The map should be rendered
      expect(page).to have_css(".placekey-map")
      
      # Click the marker
      find(".placekey-map-marker").click
      
      # Should show popup with location info
      expect(page).to have_css(".placekey-map-popup")
      expect(page).to have_content(@location.name)
    end
    
    it "updates the map when form values change" do
      visit edit_location_path(@location)
      
      # Change the coordinates
      fill_in "location[latitude]", with: "38.0"
      fill_in "location[longitude]", with: "-123.0"
      
      # Let the JS execute
      sleep 0.5
      
      # Map should update with new marker position
      # This would require a specific way to check the marker position
      # For now, we just verify the map is present
      expect(page).to have_css(".placekey-map")
    end
  end
  
  describe "Address lookup integration" do
    before do
      # Mock the API client for address lookup
      api_client = instance_double(PlacekeyRails::Client)
      allow(PlacekeyRails).to receive(:default_client).and_return(api_client)
      
      allow(api_client).to receive(:lookup_placekey) do |params|
        if params[:street_address].present?
          {
            "placekey" => "@37--122-xyz",
            "latitude" => 37.7749,
            "longitude" => -122.4194
          }
        else
          { "error" => "Missing address" }
        end
      end
    end
    
    it "performs address lookup when button is clicked" do
      visit new_location_path
      
      # Fill in address fields
      fill_in "location[name]", with: "Address Test"
      fill_in "location[street_address]", with: "123 Main St"
      fill_in "location[city]", with: "San Francisco"
      fill_in "location[region]", with: "CA"
      fill_in "location[postal_code]", with: "94105"
      
      # Click the lookup button
      click_button "Lookup Placekey"
      
      # Let the JS execute
      sleep 0.5
      
      # Coordinates and placekey should be populated
      expect(find_field("location[latitude]").value).not_to be_empty
      expect(find_field("location[longitude]").value).not_to be_empty
      expect(find_field("location[placekey]").value).not_to be_empty
    end
    
    it "shows an error when address lookup fails" do
      visit new_location_path
      
      # Click the lookup button without filling in address
      click_button "Lookup Placekey"
      
      # Let the JS execute
      sleep 0.5
      
      # Should show an error message
      expect(page).to have_css(".placekey-error")
    end
  end
  
  describe "Complete form workflow" do
    it "allows creating a location using the form and JS components" do
      visit new_location_path
      
      # Step 1: Fill in the basic information
      fill_in "location[name]", with: "Complete Workflow Test"
      
      # Step 2: Fill in coordinates
      fill_in "location[latitude]", with: "37.7749"
      fill_in "location[longitude]", with: "-122.4194"
      
      # Wait for placekey to be generated
      sleep 0.5
      
      # Step 3: Submit the form
      click_button "Create Location"
      
      # Step 4: Verify the creation was successful
      expect(page).to have_content("Location was successfully created")
      expect(page).to have_content("Complete Workflow Test")
      expect(page).to have_content("37.7749")
      expect(page).to have_content("-122.4194")
      
      # Step 5: Verify map is displayed with the correct marker
      expect(page).to have_css(".placekey-map")
      expect(page).to have_css(".placekey-map-marker")
    end
    
    it "allows updating a location with address lookup" do
      visit edit_location_path(@location)
      
      # Step 1: Update name
      fill_in "location[name]", with: "Updated Location"
      
      # Step 2: Add address information
      fill_in "location[street_address]", with: "123 Main St"
      fill_in "location[city]", with: "San Francisco"
      fill_in "location[region]", with: "CA"
      fill_in "location[postal_code]", with: "94105"
      
      # Step 3: Click lookup
      click_button "Lookup Placekey"
      
      # Wait for AJAX
      sleep 0.5
      
      # Step 4: Submit the form
      click_button "Update Location"
      
      # Step 5: Verify update was successful
      expect(page).to have_content("Location was successfully updated")
      expect(page).to have_content("Updated Location")
      expect(page).to have_content("123 Main St")
      
      # Step 6: Check that map is still displayed
      expect(page).to have_css(".placekey-map")
    end
  end
  
  describe "Map interaction with multiple locations" do
    before do
      # Create additional test locations
      @locations = []
      3.times do |i|
        @locations << Location.create!(
          name: "Map Test Location #{i}",
          latitude: 37.7749 + (i * 0.01),
          longitude: -122.4194 - (i * 0.01)
        )
      end
    end
    
    it "displays all locations on the index page map" do
      visit locations_path
      
      # Map should have multiple markers (one for each location)
      expect(page).to have_css(".placekey-map-marker", count: @locations.size + 1)  # +1 for original test location
    end
    
    it "centers the map appropriately to show all markers" do
      visit locations_path
      
      # This is hard to test without deeper JS interaction
      # Just verify the map exists
      expect(page).to have_css(".placekey-map")
    end
    
    it "allows filtering locations shown on the map" do
      # This would require custom filtering UI to be implemented
      pending "Map filtering not implemented yet"
      
      visit locations_path
      
      # Use filter controls (if implemented)
      select "Map Test Location 0", from: "filter_location"
      
      # Wait for map to update
      sleep 0.5
      
      # Should only show one marker
      expect(page).to have_css(".placekey-map-marker", count: 1)
    end
  end
  
  describe "Resilience to errors" do
    it "handles invalid coordinate input gracefully" do
      visit new_location_path
      
      # Enter invalid coordinates
      fill_in "location[latitude]", with: "not-a-number"
      fill_in "location[longitude]", with: "-122.4194"
      
      # Let the JS execute
      sleep 0.5
      
      # Should show validation error
      expect(page).to have_css(".placekey-error")
      
      # Map should still be functional
      expect(page).to have_css(".placekey-map")
    end
    
    it "recovers from failed API requests" do
      # Mock API failure
      api_client = instance_double(PlacekeyRails::Client)
      allow(PlacekeyRails).to receive(:default_client).and_return(api_client)
      allow(api_client).to receive(:lookup_placekey).and_raise("API Error")
      
      visit new_location_path
      
      # Fill in address fields
      fill_in "location[street_address]", with: "123 Main St"
      fill_in "location[city]", with: "San Francisco"
      
      # Try address lookup which will fail
      click_button "Lookup Placekey"
      
      # Let the JS execute
      sleep 0.5
      
      # Should show error message
      expect(page).to have_css(".placekey-error")
      
      # But form should still be usable - try direct coordinate entry
      fill_in "location[latitude]", with: "37.7749"
      fill_in "location[longitude]", with: "-122.4194"
      
      # Form should still submit successfully
      click_button "Create Location"
      
      # Creation should succeed despite earlier API failure
      expect(page).to have_content("Location was successfully created")
    end
  end
end
