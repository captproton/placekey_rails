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
        parts = placekey.split("@")
        
        # If placekey starts with @, adjust the parsing
        if placekey.start_with?("@")
          what = nil
          where = placekey[1..-1]  # Remove the @ symbol
        elsif parts.length > 1
          what = parts[0]
          where = parts[1]
        else
          what = nil
          where = parts[0]
        end

        # Validate the parts
        if what
          what_valid = (WHAT_REGEX_V1.match?(what) || WHAT_REGEX_V2.match?(what))
          return false unless what_valid
        end

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
  end
end