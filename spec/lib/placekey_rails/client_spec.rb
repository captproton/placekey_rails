require 'rails_helper'

RSpec.describe PlacekeyRails::Client do
  let(:api_key) { "test_api_key" }
  let(:client) { described_class.new(api_key) }
  let(:logger) { instance_double(ActiveSupport::Logger, info: nil, error: nil) }

  before do
    allow(client).to receive(:logger).and_return(logger)
  end

  describe "#initialize" do
    it "initializes with an API key" do
      expect(client.api_key).to eq(api_key)
    end

    it "accepts optional parameters" do
      client_with_options = described_class.new(api_key, max_retries: 10)
      expect(client_with_options.max_retries).to eq(10)
    end

    it "sets default values for optional parameters" do
      expect(client.max_retries).to eq(20)
    end
  end

  describe "#validate_query!" do
    it "accepts valid parameters" do
      valid_query = {
        'latitude' => 37.7371,
        'longitude' => -122.44283,
        'query_id' => 'test1'
      }
      expect { client.send(:validate_query!, valid_query) }.not_to raise_error
    end

    it "accepts valid place_metadata parameters" do
      valid_query = {
        'latitude' => 37.7371,
        'longitude' => -122.44283,
        'place_metadata' => {
          'store_id' => '1234',
          'phone_number' => '555-1234'
        }
      }
      expect { client.send(:validate_query!, valid_query) }.not_to raise_error
    end

    it "rejects invalid top-level parameters" do
      invalid_query = {
        'latitude' => 37.7371,
        'invalid_param' => 'value'
      }
      expect { client.send(:validate_query!, invalid_query) }.to raise_error(ArgumentError, /Invalid query parameters/)
    end

    it "rejects invalid place_metadata parameters" do
      invalid_query = {
        'latitude' => 37.7371,
        'longitude' => -122.44283,
        'place_metadata' => {
          'invalid_metadata' => 'value'
        }
      }
      expect { client.send(:validate_query!, invalid_query) }.to raise_error(ArgumentError, /Invalid place_metadata parameters/)
    end
  end

  describe "#has_minimum_inputs?" do
    it "accepts latitude and longitude" do
      expect(client.send(:has_minimum_inputs?, ['latitude', 'longitude'])).to be true
    end

    it "accepts full address" do
      expect(client.send(:has_minimum_inputs?, ['street_address', 'city', 'region', 'postal_code'])).to be true
    end

    it "accepts address with region and postal code" do
      expect(client.send(:has_minimum_inputs?, ['street_address', 'region', 'postal_code'])).to be true
    end

    it "accepts address with region and city" do
      expect(client.send(:has_minimum_inputs?, ['street_address', 'region', 'city'])).to be true
    end

    it "rejects insufficient inputs" do
      expect(client.send(:has_minimum_inputs?, ['street_address'])).to be false
      expect(client.send(:has_minimum_inputs?, ['city', 'region'])).to be false
    end
  end

  describe "#lookup_placekey" do
    let(:valid_query) { { 'latitude' => 37.7371, 'longitude' => -122.44283 } }
    let(:success_response) { instance_double(HTTParty::Response, code: 200, body: '{"placekey": "@5vg-82n-kzz"}') }
    let(:rate_limit_response) { instance_double(HTTParty::Response, code: 429, body: 'Rate limit exceeded') }
    let(:error_response) { instance_double(HTTParty::Response, code: 400, body: '{"error": "Invalid request"}') }

    it "sends a request with the correct parameters" do
      expect(described_class).to receive(:post).with(
        '/placekey',
        hash_including(
          body: { query: valid_query }.to_json,
          headers: hash_including('apikey' => api_key)
        )
      ).and_return(success_response)

      client.lookup_placekey(valid_query)
    end

    it "parses a successful response" do
      allow(described_class).to receive(:post).and_return(success_response)
      result = client.lookup_placekey(valid_query)
      expect(result).to eq({ "placekey" => "@5vg-82n-kzz" })
    end

    it "handles rate limit errors" do
      allow(described_class).to receive(:post).and_return(rate_limit_response)
      expect { client.lookup_placekey(valid_query) }.to raise_error(PlacekeyRails::RateLimitExceededError)
    end

    it "handles other API errors" do
      allow(described_class).to receive(:post).and_return(error_response)
      expect { client.lookup_placekey(valid_query) }.to raise_error(PlacekeyRails::ApiError)
    end
  end

  describe "#lookup_placekeys" do
    let(:places) do
      [
        { 'latitude' => 37.7371, 'longitude' => -122.44283 },
        { 'street_address' => '598 Portola Dr', 'city' => 'San Francisco', 'region' => 'CA', 'postal_code' => '94131' }
      ]
    end

    let(:batch_response) do
      instance_double(
        HTTParty::Response,
        code: 200,
        body: '[{"query_id":"place_0","placekey":"@5vg-82n-kzz"},{"query_id":"place_1","placekey":"227-223@5vg-82n-pgk"}]'
      )
    end

    it "adds query_ids to places without them" do
      allow(client).to receive(:lookup_batch).and_return([])
      client.lookup_placekeys(places)
      expect(places[0]['query_id']).to eq('place_0')
      expect(places[1]['query_id']).to eq('place_1')
    end

    it "processes places in batches" do
      expect(client).to receive(:lookup_batch).once.and_return([])
      client.lookup_placekeys(places)
    end

    it "returns results for all places" do
      allow(client).to receive(:lookup_batch).and_return(
        [
          { 'query_id' => 'place_0', 'placekey' => '@5vg-82n-kzz' },
          { 'query_id' => 'place_1', 'placekey' => '227-223@5vg-82n-pgk' }
        ]
      )

      results = client.lookup_placekeys(places)
      expect(results.size).to eq(2)
      expect(results[0]['placekey']).to eq('@5vg-82n-kzz')
      expect(results[1]['placekey']).to eq('227-223@5vg-82n-pgk')
    end

    it "handles errors in a batch" do
      allow(client).to receive(:lookup_batch).and_return({ 'error' => 'Batch error' })
      
      results = client.lookup_placekeys(places)
      expect(results.size).to eq(2)
      expect(results[0]['error']).to eq('Batch error')
      expect(results[1]['error']).to eq('Batch error')
    end

    it "enforces maximum batch size" do
      expect { client.lookup_placekeys(places, nil, 101) }.to raise_error(ArgumentError, /Batch size cannot exceed/)
    end
  end

  describe "#lookup_batch" do
    let(:places) do
      [
        { 'latitude' => 37.7371, 'longitude' => -122.44283, 'query_id' => 'place_0' },
        { 'street_address' => '598 Portola Dr', 'city' => 'San Francisco', 'region' => 'CA', 'postal_code' => '94131', 'query_id' => 'place_1' }
      ]
    end

    let(:batch_response) do
      instance_double(
        HTTParty::Response,
        code: 200,
        body: '[{"query_id":"place_0","placekey":"@5vg-82n-kzz"},{"query_id":"place_1","placekey":"227-223@5vg-82n-pgk"}]'
      )
    end

    it "sends a request with the correct parameters" do
      expect(described_class).to receive(:post).with(
        '/placekeys',
        hash_including(
          body: { queries: places }.to_json,
          headers: hash_including('apikey' => api_key)
        )
      ).and_return(batch_response)

      client.send(:lookup_batch, places)
    end

    it "enforces maximum batch size" do
      expect { client.send(:lookup_batch, Array.new(101)) }.to raise_error(ArgumentError, /number of places in a batch/)
    end
  end

  describe ".list_free_datasets" do
    let(:success_response) { instance_double(HTTParty::Response, code: 200, body: '["dataset1", "dataset2"]') }
    let(:error_response) { instance_double(HTTParty::Response, code: 500, body: 'Server error') }

    it "parses a successful response" do
      allow(described_class).to receive(:get_with_limiter).and_return(success_response)
      result = described_class.list_free_datasets
      expect(result).to eq(['dataset1', 'dataset2'])
    end

    it "handles API errors" do
      allow(described_class).to receive(:get_with_limiter).and_return(error_response)
      expect { described_class.list_free_datasets }.to raise_error(PlacekeyRails::ApiError)
    end
  end

  describe ".return_free_datasets_location_by_name" do
    let(:success_response) { instance_double(HTTParty::Response, code: 200, body: 'https://example.com/dataset') }
    let(:not_found_response) { instance_double(HTTParty::Response, code: 404, reason: 'Not Found', body: 'Not found') }

    it "parses a successful response" do
      allow(described_class).to receive(:get_with_limiter).with(
        'https://api.placekey.io/placekey-py/v1/get-public-dataset-location-from-name',
        hash_including(query: { name: 'dataset1', url: false })
      ).and_return(success_response)

      result = described_class.return_free_datasets_location_by_name('dataset1')
      expect(result).to eq('https://example.com/dataset')
    end

    it "handles not found errors" do
      allow(described_class).to receive(:get_with_limiter).and_return(not_found_response)
      expect { described_class.return_free_datasets_location_by_name('invalid') }.to raise_error(ArgumentError, 'Not Found')
    end
  end

  describe ".return_free_dataset_joins_by_name" do
    let(:success_response) { instance_double(HTTParty::Response, code: 200, body: '{"join_url": "https://example.com/join"}') }
    let(:error_response) { instance_double(HTTParty::Response, code: 400, reason: 'Bad Request', body: 'Invalid dataset names') }

    it "parses a successful response" do
      allow(described_class).to receive(:get_with_limiter).with(
        'https://api.placekey.io/placekey-py/v1/get-public-join-from-names',
        hash_including(query: { public_datasets: 'dataset1,dataset2', url: false })
      ).and_return(success_response)

      result = described_class.return_free_dataset_joins_by_name(['dataset1', 'dataset2'])
      expect(result).to eq({ "join_url" => "https://example.com/join" })
    end

    it "handles error responses" do
      allow(described_class).to receive(:get_with_limiter).and_return(error_response)
      expect { described_class.return_free_dataset_joins_by_name(['invalid']) }.to raise_error(ArgumentError, 'Bad Request')
    end
  end
end
