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

    # Normalize a placekey to match the standard format
    # This ensures compatibility between API-returned placekeys and validation
    def normalize_placekey_format(placekey)
      return placekey unless placekey.is_a?(String)
      
      if placekey.include?('@')
        parts = placekey.split('@', 2)
        
        # Case 1: @where format (already correct)
        if parts[0].empty?
          return placekey
        
        # Case 2: Simple numeric prefix (like "23b@") - convert to @where format
        elsif parts[0].match?(/^\d+[a-z]?$/)
          return "@#{parts[1]}"
        
        # Case 3: Proper what part but missing dash (like "223@xxx-xxx-xxx")
        elsif parts[0].match?(/^[23456789bcdfghjkmnpqrstvwxyz]{3,6}$/) && !parts[0].include?('-')
          if parts[0].length == 6
            # Split into two triplets if exactly 6 characters
            what = "#{parts[0][0..2]}-#{parts[0][3..5]}"
            return "#{what}@#{parts[1]}"
          elsif parts[0].length == 3
            # Special case for just address code
            return "#{parts[0]}-@#{parts[1]}"
          end
        end
      end
      
      # No changes needed or format not recognized
      placekey
    end
  end
end
