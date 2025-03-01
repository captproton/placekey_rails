require 'placekey_rails/constants'
require 'placekey_rails/h3_adapter'
require 'placekey_rails/converter'

module PlacekeyRails
  module Validator
    extend self

    # Regular expressions for placekey validation
    WHERE_REGEX = /^[#{ALPHABET}#{REPLACEMENT_CHARS}#{PADDING_CHAR}]{3}-[#{ALPHABET}#{REPLACEMENT_CHARS}]{3}-[#{ALPHABET}#{REPLACEMENT_CHARS}]{3}$/
    WHAT_REGEX_V1 = /^[#{ALPHABET}]{3,}(-[#{ALPHABET}]{3,})?$/
    WHAT_REGEX_V2 = /^[01][abcdefghijklmnopqrstuvwxyz234567]{9}$/
    
    def placekey_format_is_valid(placekey)
      begin
        parts = placekey.split('@')
        what = parts.length > 1 ? parts[0] : nil
        where = parts.length > 1 ? parts[1] : parts[0]
        
        # If placekey starts with @, adjust the parsing
        if placekey.start_with?('@')
          what = nil
          where = placekey[1..-1]  # Remove the @ symbol
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
        h3_index = Converter.placekey_to_h3(placekey)
        H3Adapter.is_valid_cell(H3Adapter.string_to_h3(h3_index))
      rescue StandardError => e
        false
      end
    end
  end
end
