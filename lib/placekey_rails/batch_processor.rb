module PlacekeyRails
  # BatchProcessor provides optimized methods for processing large sets of records
  # with Placekey operations, focusing on performance and memory efficiency.
  class BatchProcessor
    attr_reader :batch_size, :logger, :options

    # Initialize a new BatchProcessor
    # @param options [Hash] Options for the batch processor
    # @option options [Integer] :batch_size Number of records to process in each batch (default: 100)
    # @option options [Logger] :logger Logger to use for reporting progress
    def initialize(options = {})
      @batch_size = options[:batch_size] || 100
      @logger = options[:logger] || Rails.logger
      @options = options
    end

    # Process a large collection of records with a Placekey operation
    # @param collection [ActiveRecord::Relation, Array] Collection to process
    # @param operation [Symbol, Proc] Operation to perform on each record
    # @yield [processed, successful] Block called after each batch with progress stats
    # @return [Hash] Results of the processing operation
    def process(collection, operation, &block)
      total = collection.respond_to?(:count) ? collection.count : collection.size
      processed = 0
      successful = 0
      errors = []

      log_info("Starting batch processing of #{total} records")

      process_in_batches(collection) do |batch|
        batch_results = process_batch(batch, operation)
        
        processed += batch.size
        successful += batch_results[:successful]
        errors.concat(batch_results[:errors])

        log_progress(processed, total, successful, errors.size)
        yield(processed, successful) if block_given?
      end

      log_info("Completed batch processing: #{processed} processed, #{successful} successful, #{errors.size} errors")
      
      {
        total: total,
        processed: processed,
        successful: successful,
        errors: errors
      }
    end

    # Geocode a collection of records using their address fields
    # @param collection [ActiveRecord::Relation, Array] Collection to geocode
    # @param address_mapping [Hash] Mapping of model fields to address fields
    # @yield [processed, successful] Block called after each batch with progress stats
    # @return [Hash] Results of the geocoding operation
    def geocode(collection, address_mapping = {}, &block)
      ensure_client_setup
      
      process(collection, -> (record) { geocode_record(record, address_mapping) }, &block)
    end

    # Generate placekeys for a collection of records with coordinates
    # @param collection [ActiveRecord::Relation, Array] Collection to process
    # @param lat_field [Symbol] Field containing latitude
    # @param lng_field [Symbol] Field containing longitude
    # @yield [processed, successful] Block called after each batch with progress stats
    # @return [Hash] Results of the processing operation
    def generate_placekeys(collection, lat_field: :latitude, lng_field: :longitude, &block)
      process(collection, -> (record) { generate_placekey(record, lat_field, lng_field) }, &block)
    end

    # Find records near a point within a specified distance
    # @param collection [ActiveRecord::Relation, Array] Collection to search
    # @param lat [Float] Latitude of the center point
    # @param lng [Float] Longitude of the center point
    # @param distance [Float] Maximum distance in meters
    # @param placekey_field [Symbol] Field containing the placekey
    # @return [Array] Records within the distance
    def find_nearby(collection, lat, lng, distance, placekey_field: :placekey)
      log_info("Finding records within #{distance}m of (#{lat}, #{lng})")
      
      # Generate a placekey for the center point
      center_placekey = PlacekeyRails.geo_to_placekey(lat, lng)
      
      # Estimate an appropriate grid distance based on meters
      grid_distance = estimate_grid_distance(distance)
      log_info("Using grid distance #{grid_distance} for spatial search")
      
      # Get all potential neighbors at the grid distance
      neighbor_keys = PlacekeyRails.get_neighboring_placekeys(center_placekey, grid_distance).to_a
      
      # Filter the collection to records with those placekeys
      candidates = if collection.is_a?(ActiveRecord::Relation)
        collection.where(placekey_field => neighbor_keys)
      else
        collection.select { |record| neighbor_keys.include?(record.send(placekey_field)) }
      end
      
      log_info("Found #{candidates.size} candidate records within grid distance")
      
      # Further filter by exact distance
      results = candidates.select do |record|
        record_placekey = record.send(placekey_field)
        next false unless record_placekey.present?
        
        PlacekeyRails.placekey_distance(center_placekey, record_placekey) <= distance
      end
      
      log_info("Found #{results.size} records within #{distance}m")
      results
    end

    private

    def process_in_batches(collection, &block)
      if collection.is_a?(ActiveRecord::Relation)
        collection.find_in_batches(batch_size: batch_size, &block)
      else
        collection.each_slice(batch_size, &block)
      end
    end

    def process_batch(batch, operation)
      successful = 0
      errors = []

      batch.each do |record|
        begin
          result = if operation.is_a?(Symbol)
            record.send(operation)
          else
            operation.call(record)
          end
          
          successful += 1 if result
        rescue => e
          errors << { record: record, error: e.message }
          log_error("Error processing record #{record.id}: #{e.message}")
        end
      end

      { successful: successful, errors: errors }
    end

    def geocode_record(record, address_mapping)
      return false if record.placekey.present?
      
      # If the record has coordinates, generate a placekey from them
      if record.respond_to?(:latitude) && record.respond_to?(:longitude) &&
         record.latitude.present? && record.longitude.present?
        return generate_placekey(record, :latitude, :longitude)
      end
      
      # Extract address fields from the record
      query = extract_address_fields(record, address_mapping)
      return false unless query.values.any?(&:present?)
      
      # Look up the placekey for the address
      result = PlacekeyRails.lookup_placekey(query)
      
      if result && result["placekey"].present?
        record.update(placekey: result["placekey"])
        true
      else
        false
      end
    end

    def generate_placekey(record, lat_field, lng_field)
      return false if record.placekey.present?
      
      lat = record.send(lat_field)
      lng = record.send(lng_field)
      
      return false unless lat.present? && lng.present?
      
      record.placekey = PlacekeyRails.geo_to_placekey(lat.to_f, lng.to_f)
      record.save
    end

    def extract_address_fields(record, mapping)
      default_mapping = {
        street_address: :street_address,
        city: :city,
        region: :region,
        postal_code: :postal_code,
        iso_country_code: :country_code
      }
      
      field_mapping = default_mapping.merge(mapping)
      
      query = {}
      field_mapping.each do |api_field, record_field|
        if record.respond_to?(record_field) && record.send(record_field).present?
          query[api_field] = record.send(record_field)
        end
      end
      
      query[:query_id] = record.id.to_s
      query
    end

    def estimate_grid_distance(meters)
      if meters > 20000
        3  # For very large distances, use a large grid distance
      elsif meters > 5000
        2  # For medium distances
      else
        1  # For small distances
      end
    end

    def ensure_client_setup
      unless PlacekeyRails.default_client
        raise Error, "Default API client not set up. Call PlacekeyRails.setup_client(api_key) first."
      end
    end

    def log_info(message)
      logger.info("[PlacekeyRails::BatchProcessor] #{message}") if logger
    end

    def log_error(message)
      logger.error("[PlacekeyRails::BatchProcessor] #{message}") if logger
    end

    def log_progress(processed, total, successful, errors)
      return unless logger
      
      percent = total > 0 ? (processed.to_f / total * 100).round(1) : 0
      logger.info("[PlacekeyRails::BatchProcessor] Processed: #{processed}/#{total} (#{percent}%), Successful: #{successful}, Errors: #{errors}")
    end
  end
end
