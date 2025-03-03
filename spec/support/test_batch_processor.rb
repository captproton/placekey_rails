module PlacekeyRails
  # A simplified BatchProcessor for testing
  class TestBatchProcessor
    attr_reader :records

    def initialize(records)
      @records = records
    end

    def process
      records.map do |record|
        begin
          # Try to generate placekey if needed
          if record.placekey.blank? && record.coordinates_available?
            record.generate_placekey
            record.save
          end

          {
            id: record.id,
            name: record.name,
            original_placekey: record.placekey,
            placekey: record.placekey,
            success: true
          }
        rescue => e
          {
            id: record.id,
            name: record&.name,
            original_placekey: record&.placekey,
            placekey: nil,
            success: false,
            error: e.message
          }
        end
      end
    end
  end
end

# For testing, replace the actual BatchProcessor with our simplified version
RSpec.configure do |config|
  config.before(:each, type: :integration) do
    stub_const("PlacekeyRails::BatchProcessor", PlacekeyRails::TestBatchProcessor)
  end
end
