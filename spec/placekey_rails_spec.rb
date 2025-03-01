require 'rails_helper'

RSpec.describe PlacekeyRails do
  it "is a module" do
    expect(described_class).to be_a(Module)
  end

  it "has a version number" do
    expect(PlacekeyRails::VERSION).not_to be_nil
  end
end

RSpec.describe PlacekeyRails::Engine do
  it "is an engine" do
    expect(described_class.superclass).to eq(Rails::Engine)
  end

  it "isolates its namespace" do
    expect(described_class.isolated?).to be true
  end
end