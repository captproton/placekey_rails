require 'rails_helper'

RSpec.describe PlacekeyRails::ApplicationController, type: :controller do
  it "is a subclass of ActionController::Base" do
    expect(described_class.superclass).to eq(ActionController::Base)
  end

  it "uses the engine's layout" do
    expect(described_class._layout).to eq("placekey_rails/application")
  end
end
