require "placekey_rails/constants"
require "placekey_rails/h3_adapter"
require "placekey_rails/converter"

module PlacekeyRails
  module Validator
    extend self

    # Regular expressions for placekey validation
    WHERE_REGEX = /^[23456789bcdfghjkmnpqrstvwxyz]{3}-[23456789bcdfghjkmnpqrstvwxyz]{3}-[23456789bcdfghjkmnpqrstvwxyz]{3}$/
    WHAT_REGEX_V1 = /^[23456789bcdfghjkmnpqrstvwxyz]{3,}-[23456789bcdfghjkmnpqrstvwxyz]{3,}$/
    WHAT_REGEX_V2 = /^[01][abcdefghijklmnopqrstvwxyz234567]{9}$/
    PLACEKEY_REGEX = /^(@|[23456789bcdfghjkmnpqrstvwxyz]{3,}-[23456789bcdfghjkmnpqrstvwxyz]{3,}@)?[23456789bcdfghjkmnpqrstvwxyz]{3}-[23456789bcdfghjkmnpqrstvwxyz]{3}-[23456789bcdfghjkmnpqrstvwxyz]{3}$/

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
        
        # Case 3: Proper what part but missing dash in a 6-char sequence
        # Like "223227@xxx-xxx-xxx" should be "223-227@xxx-xxx-xxx"
        elsif what_part.match?(/^[23456789bcdfghjkmnpqrstvwxyz]{6}$/) && !what_part.include?('-')
          # Split into two triplets if exactly 6 characters
          formatted_what = "#{what_part[0..2]}-#{what_part[3..5]}"
          return "#{formatted_what}@#{where_part}"
          
        # Case 4: Single address code without POI code and missing dash
        # Like "223@xxx-xxx-xxx" should be "223-@xxx-xxx-xxx"
        elsif what_part.match?(/^[23456789bcdfghjkmnpqrstvwxyz]{3}$/) && !what_part.include?('-')
          # Add a dash to follow the format in the white paper
          return "#{what_part}-@#{where_part}"
        
        # Case 2: Numeric prefix - convert to @where format
        # API sometimes returns formats like "23b@5vg-849-gp9"
        # According to the white paper, these should be "@where" format
        elsif what_part.match?(/^\d+[a-z]*$/)
          return "@#{where_part}"
        end
      else
        # Case 5: Where part without @ symbol (like "5vg-82n-kzz")
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