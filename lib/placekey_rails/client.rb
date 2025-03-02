require "httparty"
require "placekey_rails/constants"

module PlacekeyRails
  class Client
    include HTTParty
    base_uri "https://api.placekey.io/v1"

    QUERY_PARAMETERS = %w[
      latitude longitude location_name street_address
      city region postal_code iso_country_code query_id
      place_metadata
    ].to_set.freeze

    PLACE_METADATA_PARAMETERS = %w[
      store_id phone_number website naics_code mcc_code
    ].to_set.freeze

    DEFAULT_QUERY_ID_PREFIX = "place_"

    MIN_INPUTS = [
      [ "latitude", "longitude" ],
      [ "street_address", "city", "region", "postal_code" ],
      [ "street_address", "region", "postal_code" ],
      [ "street_address", "region", "city" ]
    ]

    REQUEST_LIMIT = 1000
    REQUEST_WINDOW = 60
    BULK_REQUEST_LIMIT = 10
    BULK_REQUEST_WINDOW = 60
    MAX_BATCH_SIZE = 100

    attr_reader :api_key, :max_retries, :logger

    def initialize(api_key, options = {})
      @api_key = api_key
      @max_retries = options[:max_retries] || 20
      @logger = options[:logger] || Rails.logger
      @user_agent_comment = options[:user_agent_comment]
      @use_cache = options[:use_cache].nil? ? true : options[:use_cache]

      @headers = {
        "Content-Type" => "application/json",
        "User-Agent" => "placekey-rails/#{PlacekeyRails::VERSION}",
        "apikey" => @api_key
      }

      if @user_agent_comment.is_a?(String)
        @headers["User-Agent"] = "#{@headers['User-Agent']} #{@user_agent_comment}".strip
      end

      @single_request_limiter = RateLimiter.new(
        limit: REQUEST_LIMIT,
        period: REQUEST_WINDOW
      )

      @bulk_request_limiter = RateLimiter.new(
        limit: BULK_REQUEST_LIMIT,
        period: BULK_REQUEST_WINDOW
      )
    end

    def lookup_placekey(params = {}, fields = nil)
      validate_query!(params)

      # Use cache if enabled and available
      cache_key = nil
      if @use_cache && PlacekeyRails.cache
        cache_key = "lookup:#{params.to_json}:#{fields.to_json}"
        cached_result = PlacekeyRails.cache.get(cache_key)
        return cached_result if cached_result
      end

      payload = { query: params }
      payload[:options] = { fields: fields } if fields

      response = with_rate_limit(@single_request_limiter) do
        self.class.post("/placekey",
          body: payload.to_json,
          headers: @headers
        )
      end

      result = handle_response(response)
      
      # Cache the result if caching is enabled
      if cache_key && PlacekeyRails.cache
        PlacekeyRails.cache.set(cache_key, result)
      end
      
      result
    end

    def lookup_placekeys(places, fields = nil, batch_size = MAX_BATCH_SIZE, verbose = false)
      if batch_size > MAX_BATCH_SIZE
        raise ArgumentError, "Batch size cannot exceed #{MAX_BATCH_SIZE}"
      end

      places.each do |place|
        validate_query!(place)
      end

      log_level = verbose ? :info : :error

      # Add a query_id to each place that doesn't have one
      places.each_with_index do |place, i|
        place["query_id"] ||= "#{DEFAULT_QUERY_ID_PREFIX}#{i}"
      end

      results = []
      
      # Check cache for already processed places
      if @use_cache && PlacekeyRails.cache
        cached_places = []
        uncached_places = []
        
        places.each do |place|
          cache_key = "lookup:#{place.to_json}:#{fields.to_json}"
          cached_result = PlacekeyRails.cache.get(cache_key)
          
          if cached_result
            results << cached_result
            cached_places << place
          else
            uncached_places << place
          end
        end
        
        if cached_places.any? && verbose
          logger.info("Found #{cached_places.size} places in cache")
        end
        
        # Continue with only uncached places
        places = uncached_places
      end
      
      # Process any remaining uncached places
      (0...places.size).step(batch_size) do |i|
        max_batch_idx = [ i + batch_size, places.size ].min
        batch_query_ids = places[i...max_batch_idx].map { |p| p["query_id"] }

        begin
          batch_results = lookup_batch(places[i...max_batch_idx], fields)

          # Handle different result formats
          if batch_results.is_a?(Hash) && batch_results.key?("error")
            logger.info("All queries in batch (#{i}, #{max_batch_idx}) had errors") if verbose
            batch_results = batch_query_ids.map { |query_id| { "query_id" => query_id, "error" => batch_results["error"] } }
          elsif batch_results.is_a?(Hash) && batch_results.key?("message")
            logger.error(batch_results["message"])
            logger.error("Returning completed queries")
            break
          end
          
          # Cache individual results if caching is enabled
          if @use_cache && PlacekeyRails.cache && batch_results.is_a?(Array)
            batch_results.each_with_index do |result, j|
              if result && !result.key?("error")
                place_index = i + j
                if place_index < places.size
                  cache_key = "lookup:#{places[place_index].to_json}:#{fields.to_json}"
                  PlacekeyRails.cache.set(cache_key, result)
                end
              end
            end
          end

          results.concat(Array(batch_results))
        rescue RateLimitExceededError, HTTParty::Error => e
          logger.error("Fatal error encountered: #{e.message}. Returning processed items at size #{i} of #{places.size}")
          break
        end

        if verbose && max_batch_idx % (10 * batch_size) == 0 && i > 0
          logger.info("Processed #{max_batch_idx} items")
        end
      end

      logger.info("Processed #{results.size} items") if verbose
      logger.info("Done") if verbose

      results
    end

    def placekey_dataframe(dataframe, column_mapping, fields = nil, batch_size = MAX_BATCH_SIZE, verbose = false)
      unless has_minimum_inputs?(column_mapping.keys)
        raise ArgumentError, "The inputted DataFrame doesn't have enough information. Refer to minimum inputs documentation."
      end

      validate_query!(column_mapping)

      temp_query_id = "temp_query_id"
      dataframe[temp_query_id] = ""

      places = []

      dataframe.each_row_with_index do |row, i|
        place = {}
        column_mapping.each do |place_key, column_name|
          if dataframe.has_column?(column_name) && !row[column_name].nil?
            place[place_key] = row[column_name]
          end
        end

        query_id = "#{DEFAULT_QUERY_ID_PREFIX}#{i}"
        place["query_id"] = query_id
        dataframe[temp_query_id][i] = query_id
        places << place
      end

      result = lookup_placekeys(places, fields, batch_size, verbose)
      result_df = Rover::DataFrame.new(result).rename(temp_query_id => "query_id")

      dataframe.join(result_df, on: temp_query_id).tap do |df|
        df.delete(temp_query_id)
      end
    end

    def self.list_free_datasets
      response = get_with_limiter("https://api.placekey.io/placekey-py/v1/get-public-dataset-names")

      if response.code == 200
        JSON.parse(response.body)
      else
        raise ApiError.new(response.code, "Something went wrong. Please contact Placekey.")
      end
    end

    def self.return_free_datasets_location_by_name(name, url: false)
      response = get_with_limiter(
        "https://api.placekey.io/placekey-py/v1/get-public-dataset-location-from-name",
        query: { name: name, url: url }
      )

      case response.code
      when 200
        response.body
      when 400..499
        # Use response.body instead of response.reason for error message
        raise ArgumentError, "API Error: #{response.body}"
      else
        raise ApiError.new(response.code, "Something went wrong. Please contact Placekey.")
      end
    end

    def self.return_free_dataset_joins_by_name(names, url: false)
      response = get_with_limiter(
        "https://api.placekey.io/placekey-py/v1/get-public-join-from-names",
        query: { public_datasets: names.join(","), url: url }
      )

      case response.code
      when 200
        JSON.parse(response.body)
      when 400..499
        # Use response.body instead of response.reason for error message
        raise ArgumentError, "API Error: #{response.body}"
      else
        raise ApiError.new(response.code, "Something went wrong. Please contact Placekey.")
      end
    end

    private

    def self.get_with_limiter(url, options = {})
      limiter = RateLimiter.new(limit: 3, period: 60)

      limiter.wait!

      begin
        HTTParty.get(url, options)
      rescue HTTParty::Error => e
        raise ApiError.new(0, e.message)
      end
    end

    def lookup_batch(places, fields = nil)
      if places.size > MAX_BATCH_SIZE
        raise ArgumentError, "#{places.size} places submitted. The number of places in a batch can be at most #{MAX_BATCH_SIZE}"
      end

      batch_payload = { queries: places }
      batch_payload[:options] = { fields: fields } if fields

      response = with_rate_limit(@bulk_request_limiter) do
        self.class.post("/placekeys",
          body: batch_payload.to_json,
          headers: @headers
        )
      end

      handle_response(response)
    end

    def validate_query!(query)
      top_level_check = query.keys.all? { |key| QUERY_PARAMETERS.include?(key.to_s) }

      unless top_level_check
        invalid_keys = query.keys.reject { |key| QUERY_PARAMETERS.include?(key.to_s) }
        raise ArgumentError, "Invalid query parameters: #{invalid_keys.join(', ')}"
      end

      if query.key?("place_metadata") || query.key?(:place_metadata)
        metadata = query["place_metadata"] || query[:place_metadata]
        metadata_check = metadata.keys.all? { |key| PLACE_METADATA_PARAMETERS.include?(key.to_s) }

        unless metadata_check
          invalid_keys = metadata.keys.reject { |key| PLACE_METADATA_PARAMETERS.include?(key.to_s) }
          raise ArgumentError, "Invalid place_metadata parameters: #{invalid_keys.join(', ')}"
        end
      end

      true
    end

    def has_minimum_inputs?(inputs)
      MIN_INPUTS.any? do |required_keys|
        required_keys.all? { |key| inputs.include?(key) }
      end
    end

    def handle_response(response)
      case response.code
      when 200
        begin
          JSON.parse(response.body)
        rescue JSON::ParserError => e
          logger.error("Error parsing JSON: #{e.message}, returning empty list")
          []
        end
      when 429
        raise RateLimitExceededError
      else
        raise ApiError.new(response.code, response.body)
      end
    end

    def with_rate_limit(limiter)
      retries = 0

      begin
        limiter.wait!
        yield
      rescue RateLimitExceededError, HTTParty::Error => e
        retries += 1
        if retries < @max_retries
          # Exponential backoff
          sleep_time = (2 ** retries) * 0.1
          sleep(sleep_time)
          retry
        else
          raise e
        end
      end
    end
  end

  class RateLimiter
    def initialize(limit:, period:)
      @limit = limit
      @period = period
      @timestamps = []
      @mutex = Mutex.new
    end

    def wait!
      @mutex.synchronize do
        now = Time.now.to_f

        # Remove timestamps older than the rate limit period
        @timestamps.reject! { |ts| now - ts > @period }

        # If we've hit the limit, wait until we can make another request
        if @timestamps.size >= @limit
          sleep_time = @period - (now - @timestamps.first)
          sleep(sleep_time) if sleep_time > 0
        end

        @timestamps << Time.now.to_f
      end
    end
  end

  class ApiError < StandardError
    attr_reader :code

    def initialize(code, message)
      @code = code
      super(message)
    end
  end

  class RateLimitExceededError < StandardError
    def initialize
      super("Rate limit exceeded")
    end
  end
end
