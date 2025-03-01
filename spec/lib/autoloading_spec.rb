require 'rails_helper'

RSpec.describe "Module autoloading" do
  before do
    # Mock the H3 module for testing
    unless defined?(H3)
      stub_const("H3", Module.new)
      allow(H3).to receive(:latLngToCell).and_return(123456789)
      allow(H3).to receive(:cellToLatLng).and_return([37.7371, -122.44283])
      allow(H3).to receive(:stringToH3).and_return(123456789)
      allow(H3).to receive(:h3ToString).and_return("8a2830828767fff")
      allow(H3).to receive(:isValidCell).and_return(true)
    end
  end
  
  it "loads constants" do
    expect(defined?(PlacekeyRails::ALPHABET)).to eq("constant")
    expect(defined?(PlacekeyRails::RESOLUTION)).to eq("constant")
  end
  
  it "autoloads Converter module" do
    expect(defined?(PlacekeyRails::Converter)).to eq("constant")
  end
  
  it "autoloads Validator module" do
    expect(defined?(PlacekeyRails::Validator)).to eq("constant")
  end
  
  it "sets up proper module hierarchy" do
    expect(PlacekeyRails::Converter).to be_a(Module)
    expect(PlacekeyRails::Validator).to be_a(Module)
  end
end