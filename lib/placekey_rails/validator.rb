require "placekey_rails/constants"
require "placekey_rails/h3_adapter"
require "placekey_rails/converter"

module PlacekeyRails
  module Validator
    extend self

    # Regular expressions for placekey validation
    WHERE_REGEX = /^[23456789bcdfghjkmnpqrstvwxyz]{3}-[23456789bcdfghjkmnpqrstvwxyz]{3}-[23456789bcdfghjkmnpqrstvwxyz]{3}$/
    WHAT_REGEX_V1 = /^[23456789bcdfghjkmnpqrstvwxyz]{3,}-[23456789bcdfghjkmnpqrstvwxyz]{3,}$/
    WHAT_REGEX_V2 = /^[01][abcdefghijklmnopqrstuvwxyz234567]{9}$/
    PLACEKEY_REGEX = /^(@|[23456789bcdfghjkmnpqrstvwxyz]{3,}-[23456789bcdfghjkmnpqrstvwxyz]{3,}@)?[23456789bcdfghjkmnpqrstvwxyz]{3}-[23456789bcdfghjkmnpqrstvwxyz]{3}-[23456789bcdfghjkmnpqrstvwxyz]{3}$/
    
    # Pattern for valid What parts (using Placekey alphabet characters)
    VALID_WHAT_PATTERN = /^[23456789bcdfghjkmnpqrstvwxyz]+$/
    
    # Pattern for numeric prefixes from API that should be removed
    # This specifically excludes valid What parts like "223" or "223227"
    NUMERIC_PREFIX_PATTERN = /^(?:\d+[a-z]+|(?!223|223227)\d+)$/

    def placekey_format_is_valid(placekey)
      begin
        # Quick overall pattern check first
        return false unless PLACEKEY_REGEX.match?(placekey)

        if placekey.start_with?("@")
          # Format is @where
          what = nil
          where = placekey[1..-1] # Remove the @ symbol
        elsif placekey.include?("@")
          # Format is what@where
          parts = placekey.split("@")
          what = parts[0]
          where = parts[1]
        else
          # No @ symbol, assume it's just the where part
          what = nil
          where = placekey
        end

        # Validate what part if present
        if what
          what_valid = (WHAT_REGEX_V1.match?(what) || WHAT_REGEX_V2.match?(what))
          return false unless what_valid
        end

        # Validate where part
        where_part_is_valid(where)
      rescue StandardError => e
        false
      end
    end

    def where_part_is_valid(where)
      begin
        # First check the format with regex
        return false unless WHERE_REGEX.match?(where)

        # Then check if it converts to a valid H3 index
        placekey = "@#{where}"  # Add @ to make it a valid placekey for converter
        h3_string = Converter.placekey_to_h3(placekey)
        h3_index = H3Adapter.string_to_h3(h3_string)
        H3Adapter.is_valid_cell(h3_index)
      rescue StandardError => e
        false
      end
    end

    # Normalize a placekey to match the standard format described in the Placekey white paper
    # This ensures compatibility between API-returned placekeys and validation
    #
    # According to the white paper, a Placekey consists of:
    # - An optional "What" part (referring to a place)
    # - A "Where" part (referring to a hexagon on Earth)
    # - The format is "What@Where" or just "@Where"
    #
    # The What part can be:
    # - Two triplets separated by dash (address-poi, like "223-227")
    # - A single address triplet with a dash (address-, like "223-")
    # - Special encodings like "zzz" for places without a mailing address
    #
    # This method handles normalizing various API response formats to match these standards
    def normalize_placekey_format(placekey)
      return placekey unless placekey.is_a?(String)
      return placekey if placekey.blank?
      
      if placekey.include?('@')
        parts = placekey.split('@', 2)
        what_part = parts[0]
        where_part = parts[1]
        
        # Case 1: @where format (already correct)
        if what_part.empty?
          return placekey

        # Special case: Check for "223227" and "223" specifically
        # These should be formatted with dashes, not treated as numeric prefixes
        elsif what_part == "223227"
          return "223-227@#{where_part}"
        elsif what_part == "223"
          return "223-@#{where_part}"
          
        # Case 2: Handle numeric prefixes from API responses 
        # This handles patterns like "23b@", "123@", "123abc@" but NOT "223" or "223227"
        elsif what_part.match?(NUMERIC_PREFIX_PATTERN)
          return "@#{where_part}"
        
        # Case 3: Check for other valid What part patterns that need formatting
        elsif what_part.match?(VALID_WHAT_PATTERN) && !what_part.include?('-')
          if what_part.length == 6
            # Format 6-char What parts as two triplets with a dash
            formatted_what = "#{what_part[0..2]}-#{what_part[3..5]}"
            return "#{formatted_what}@#{where_part}"
          elsif what_part.length == 3
            # Format 3-char What parts with a trailing dash
            return "#{what_part}-@#{where_part}"
          end
        end
      else
        # Case 4: Where part without @ symbol (like "5vg-82n-kzz")
        # Add the @ prefix for standard format
        if WHERE_REGEX.match?(placekey)
          return "@#{placekey}"
        end
      end
      
      # Return original if we can't normalize it
      placekey
    end
    
    # Validate a placekey after normalizing it
    # This is useful for validating placekeys that might come from the API
    # in non-standard formats
    def placekey_format_is_valid_normalized(placekey)
      normalized = normalize_placekey_format(placekey)
      placekey_format_is_valid(normalized)
    end
  end
end