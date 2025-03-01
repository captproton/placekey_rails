require 'placekey_rails/constants'
require 'placekey_rails/h3_adapter'

module PlacekeyRails
  module Validator
    extend self
    
    # Use string interpolation for regex pattern rather than direct variable interpolation
    def where_regex_pattern
      "^[#{PlacekeyRails::ALPHABET}#{PlacekeyRails::REPLACEMENT_CHARS}#{PlacekeyRails::PADDING_CHAR}]{3}-[#{PlacekeyRails::ALPHABET}#{PlacekeyRails::REPLACEMENT_CHARS}]{3}-[#{PlacekeyRails::ALPHABET}#{PlacekeyRails::REPLACEMENT_CHARS}]{3}$"
    end
    
    def what_regex_v1_pattern
      "^[#{PlacekeyRails::ALPHABET}]{3,}(-[#{PlacekeyRails::ALPHABET}]{3,})?$"
    end
    
    WHAT_REGEX_V2 = /^[01][abcdefghijklmnopqrstuvwxyz234567]{9}$/
    
    def placekey_format_is_valid(placekey)
      begin
        what, where = Converter.parse_placekey(placekey)
      rescue StandardError
        return false
      end
      
      if what
        where_part_is_valid(where) && 
          (what.match?(Regexp.new(what_regex_v1_pattern)) || WHAT_REGEX_V2.match?(what))
      else
        where_part_is_valid(where)
      end
    end
    
    def where_part_is_valid(where)
      where.match?(Regexp.new(where_regex_pattern)) && 
        H3Adapter.isValidCell(Converter.placekey_to_h3_int(where))
    rescue StandardError
      false
    end
  end
end