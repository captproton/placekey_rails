require 'placekey_rails/constants'
require 'placekey_rails/h3_adapter'

module PlacekeyRails
  module Validator
    extend self

    # Regular expressions for placekey validation
    WHERE_REGEX = /^[23456789bcdfghjkmnpqrstvwxyz]{3}-[23456789bcdfghjkmnpqrstvwxyz]{3}-[23456789bcdfghjkmnpqrstvwxyz]{3}$/
    WHAT_REGEX = /^[23456789bcdfghjkmnpqrstvwxyz]{3}-[23456789bcdfghjkmnpqrstvwxyz]{3}$/
    PLACEKEY_REGEX = /^(@|[23456789bcdfghjkmnpqrstvwxyz]{3}-[23456789bcdfghjkmnpqrstvwxyz]{3}@)?[23456789bcdfghjkmnpqrstvwxyz]{3}-[23456789bcdfghjkmnpqrstvwxyz]{3}-[23456789bcdfghjkmnpqrstvwxyz]{3}$/

    def placekey_format_is_valid(placekey)
      return false unless placekey =~ PLACEKEY_REGEX

      parts = placekey.split('@')
      what = parts.length > 1 ? parts[0] : nil
      where = parts.length > 1 ? parts[1] : parts[0].sub('@', '')

      return false if what && !what_part_is_valid(what)
      where_part_is_valid(where)
    end

    def where_part_is_valid(where)
      return false unless where =~ WHERE_REGEX
      begin
        h3_int = Converter.placekey_to_h3_int(where)
        H3Adapter.is_valid_cell(h3_int)
      rescue StandardError
        false
      end
    end

    private

    def what_part_is_valid(what)
      !!(what =~ WHAT_REGEX)
    end
  end
end
