require 'spec_helper'

RSpec.describe PlacekeyRails do
  describe "configuration functionality" do
    let(:original_config) { PlacekeyRails.config.dup }
    
    after do
      # Reset the configuration after each test
      PlacekeyRails.instance_variable_set(:@config, original_config)
    end

    describe ".configure" do
      it "allows configuration through a block" do
        PlacekeyRails.configure do |config|
          config[:default_country_code] = 'CA'
          config[:api_timeout] = 20
        end

        expect(PlacekeyRails.config[:default_country_code]).to eq('CA')
        expect(PlacekeyRails.config[:api_timeout]).to eq(20)
      end

      it "returns the configuration hash" do
        result = PlacekeyRails.configure { |config| config[:api_timeout] = 15 }
        expect(result).to be_a(Hash)
        expect(result[:api_timeout]).to eq(15)
      end
      
      it "keeps existing configuration values that aren't modified" do
        original_value = PlacekeyRails.config[:validate_placekeys]
        
        PlacekeyRails.configure do |config|
          config[:api_timeout] = 30
        end
        
        expect(PlacekeyRails.config[:validate_placekeys]).to eq(original_value)
      end
    end

    describe ".batch_processor" do
      it "creates a new BatchProcessor instance" do
        processor = PlacekeyRails.batch_processor
        expect(processor).to be_a(PlacekeyRails::BatchProcessor)
      end

      it "passes options to the BatchProcessor" do
        logger = double('logger')
        processor = PlacekeyRails.batch_processor(batch_size: 50, logger: logger)
        
        expect(processor.batch_size).to eq(50)
        expect(processor.logger).to eq(logger)
      end
    end
    
    describe "batch operations" do
      let(:record_class) do
        Class.new do
          attr_accessor :id, :placekey, :latitude, :longitude
          
          def initialize(attrs = {})
            attrs.each do |k, v|
              send("#{k}=", v) if respond_to?("#{k}=")
            end
            @id ||= rand(1000)
          end
          
          def save
            true
          end
          
          def update(attrs)
            attrs.each do |k, v|
              send("#{k}=", v) if respond_to?("#{k}=")
            end
            true
          end
        end
      end
      
      let(:collection) do
        [
          record_class.new(id: '1', placekey: nil, latitude: 37.7371, longitude: -122.44283),
          record_class.new(id: '2', placekey: nil, latitude: 37.7372, longitude: -122.44284)
        ]
      end
      
      before do
        # Stub the BatchProcessor for testing
        mock_processor = instance_double(PlacekeyRails::BatchProcessor)
        allow(mock_processor).to receive(:geocode).and_return({processed: 2, successful: 2})
        allow(mock_processor).to receive(:find_nearby).and_return(collection)
        
        allow(PlacekeyRails::BatchProcessor).to receive(:new).and_return(mock_processor)
        allow(PlacekeyRails).to receive(:default_client).and_return(double('client'))
      end
      
      describe ".batch_geocode" do
        it "calls BatchProcessor#geocode with the collection" do
          result = PlacekeyRails.batch_geocode(collection)
          expect(result[:processed]).to eq(2)
          expect(result[:successful]).to eq(2)
        end
        
        it "accepts a batch_size parameter" do
          expect(PlacekeyRails::BatchProcessor).to receive(:new).with(batch_size: 50)
          PlacekeyRails.batch_geocode(collection, batch_size: 50)
        end
      end
      
      describe ".find_nearby" do
        it "calls BatchProcessor#find_nearby with the coordinates and distance" do
          result = PlacekeyRails.find_nearby(collection, 37.7371, -122.44283, 1000)
          expect(result).to eq(collection)
        end
        
        it "accepts additional options" do
          expect_any_instance_of(PlacekeyRails::BatchProcessor).to receive(:find_nearby).with(
            collection, 37.7371, -122.44283, 1000, placekey_field: :custom_field
          )
          
          PlacekeyRails.find_nearby(collection, 37.7371, -122.44283, 1000, options: {placekey_field: :custom_field})
        end
      end
    end
  end
end
