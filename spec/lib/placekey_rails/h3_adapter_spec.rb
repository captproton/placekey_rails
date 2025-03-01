require 'rails_helper'

RSpec.describe PlacekeyRails::H3Adapter do
  let(:h3) { class_double(H3).as_stubbed_const }

  before do
    # Stub methods using H3's actual method names from the H3 Ruby gem
    allow(h3).to receive(:from_geo_coordinates).and_return(123456789)
    allow(h3).to receive(:to_geo_coordinates).and_return([37.7371, -122.44283])
    allow(h3).to receive(:from_string).and_return(123456789)
    allow(h3).to receive(:to_string).and_return("8a2830828767fff")
    allow(h3).to receive(:valid?).and_return(true)
    allow(h3).to receive(:k_ring).and_return([123456789, 123456790, 123456791])
    allow(h3).to receive(:to_boundary).and_return([[37.7371, -122.44283], [37.7373, -122.44284]])
    allow(h3).to receive(:polyfill).and_return([123456789, 123456790])
  end

  describe '.lat_lng_to_cell' do
    it 'converts coordinates to H3 cell' do
      lat, lng = 37.7371, -122.44283
      resolution = 10

      result = described_class.lat_lng_to_cell(lat, lng, resolution)
      expect(result).to eq(123456789)
      expect(h3).to have_received(:from_geo_coordinates).with([lat, lng], resolution)
    end
  end

  describe '.cell_to_lat_lng' do
    it 'converts H3 cell to coordinates' do
      result = described_class.cell_to_lat_lng(123456789)
      expect(result).to eq([37.7371, -122.44283])
      expect(h3).to have_received(:to_geo_coordinates).with(123456789)
    end
  end

  describe '.string_to_h3' do
    it 'converts H3 string to integer' do
      result = described_class.string_to_h3("8a2830828767fff")
      expect(result).to eq(123456789)
      expect(h3).to have_received(:from_string).with("8a2830828767fff")
    end
  end

  describe '.h3_to_string' do
    it 'converts H3 integer to string' do
      result = described_class.h3_to_string(123456789)
      expect(result).to eq("8a2830828767fff")
      expect(h3).to have_received(:to_string).with(123456789)
    end
  end

  describe '.is_valid_cell' do
    it 'checks if H3 index is valid' do
      result = described_class.is_valid_cell(123456789)
      expect(result).to be true
      expect(h3).to have_received(:valid?).with(123456789)
    end
  end

  describe '.grid_disk' do
    it 'gets hexagon neighbors' do
      result = described_class.grid_disk(123456789, 1)
      expect(result).to eq([123456789, 123456790, 123456791])
      expect(h3).to have_received(:k_ring).with(123456789, 1)
    end
  end

  describe '.cell_to_boundary' do
    it 'gets cell boundary coordinates' do
      result = described_class.cell_to_boundary(123456789)
      expect(result).to eq([[37.7371, -122.44283], [37.7373, -122.44284]])
      expect(h3).to have_received(:to_boundary).with(123456789)
    end
  end

  describe '.polyfill' do
    let(:coordinates) { [[37.7371, -122.44283], [37.7373, -122.44284], [37.7372, -122.44282]] }
    let(:resolution) { 10 }

    it 'fills polygon with H3 cells' do
      result = described_class.polyfill(coordinates, [], resolution)
      expect(result).to eq([123456789, 123456790])
      expect(h3).to have_received(:polyfill).with(coordinates, resolution)
    end
  end
end
