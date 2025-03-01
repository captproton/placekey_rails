require 'placekey_rails/constants'
require 'placekey_rails/h3_adapter'

module PlacekeyRails
  module Converter
    extend self
    
    def geo_to_placekey(lat, long)
      h3_index = H3Adapter.latLngToCell(lat, long, PlacekeyRails::RESOLUTION)
      encode_h3_int(h3_index)
    end
    
    def placekey_to_geo(placekey)
      h3_index = placekey_to_h3_int(placekey)
      H3Adapter.cellToLatLng(h3_index)
    end
    
    def h3_to_placekey(h3_string)
      h3_int = H3Adapter.stringToH3(h3_string)
      encode_h3_int(h3_int)
    end
    
    def placekey_to_h3(placekey)
      _, where = parse_placekey(placekey)
      h3_int = decode_to_h3_int(where)
      H3Adapter.h3ToString(h3_int)
    end
    
    def h3_int_to_placekey(h3_integer)
      encode_h3_int(h3_integer)
    end
    
    def placekey_to_h3_int(placekey)
      _, where = parse_placekey(placekey)
      decode_to_h3_int(where)
    end
    
    def parse_placekey(placekey)
      if placekey.include?('@')
        parts = placekey.split('@')
        if parts.first.empty?
          # Handle the case where @ is at the beginning (no "what" part)
          [nil, parts.last]
        else
          [parts.first, parts.last]
        end
      else
        [nil, placekey]
      end
    end
    
    private
    
    def encode_h3_int(h3_integer)
      short_h3_integer = shorten_h3_integer(h3_integer)
      encoded_short_h3 = encode_short_int(short_h3_integer)
      
      clean_encoded_short_h3 = clean_string(encoded_short_h3)
      if clean_encoded_short_h3.length <= PlacekeyRails::CODE_LENGTH
        clean_encoded_short_h3 = clean_encoded_short_h3.rjust(PlacekeyRails::CODE_LENGTH, PlacekeyRails::PADDING_CHAR)
      end
      
      '@' + clean_encoded_short_h3.scan(/.{#{PlacekeyRails::TUPLE_LENGTH}}/).join('-')
    end
    
    def encode_short_int(x)
      return PlacekeyRails::ALPHABET[0] if x == 0
      
      result = ''
      while x > 0
        remainder = x % PlacekeyRails::ALPHABET_LENGTH
        result = PlacekeyRails::ALPHABET[remainder] + result
        x = x / PlacekeyRails::ALPHABET_LENGTH
      end
      result
    end
    
    def decode_to_h3_int(where_part)
      code = strip_encoding(where_part)
      dirty_encoding = dirty_string(code)
      short_h3_integer = decode_string(dirty_encoding)
      unshorten_h3_integer(short_h3_integer)
    end
    
    def decode_string(s)
      val = 0
      s.each_char.with_index do |char, i|
        val += (PlacekeyRails::ALPHABET_LENGTH ** i) * PlacekeyRails::ALPHABET.index(s[-1 - i])
      end
      val
    end
    
    def strip_encoding(s)
      s.gsub('@', '').gsub('-', '').gsub(PlacekeyRails::PADDING_CHAR, '')
    end
    
    def shorten_h3_integer(h3_integer)
      if h3_integer.is_a?(String)
        h3_integer = H3Adapter.stringToH3(h3_integer)
      end
      
      # Equivalent of Python's logic
      base_cell_shift = 2 ** (3 * 15)
      out = (h3_integer + base_cell_shift) % (2 ** 52)
      out >> (3 * (15 - PlacekeyRails::BASE_RESOLUTION))
    end
    
    def unshorten_h3_integer(short_h3_integer)
      # Equivalent to Python's logic
      header_int = get_header_int
      base_cell_shift = 2 ** (3 * 15)
      unused_resolution_filler = 2 ** (3 * (15 - PlacekeyRails::BASE_RESOLUTION)) - 1
      
      unshifted_int = short_h3_integer << (3 * (15 - PlacekeyRails::BASE_RESOLUTION))
      header_int + unused_resolution_filler - base_cell_shift + unshifted_int
    end
    
    def get_header_int
      # Calculate header_int from the H3 index of (0,0)
      h3_binary = H3Adapter.latLngToCell(0.0, 0.0, PlacekeyRails::RESOLUTION).to_s(2).rjust(64, '0')
      header_bits = h3_binary[0..11]
      
      header_int = 0
      header_bits.reverse.each_char.with_index do |bit, i|
        header_int += bit.to_i * 2 ** i
      end
      
      header_int * (2 ** 52)
    end
    
    def clean_string(s)
      PlacekeyRails::REPLACEMENT_MAP.each do |k, v|
        s = s.gsub(k, v) if s.include?(k)
      end
      s
    end
    
    def dirty_string(s)
      PlacekeyRails::REPLACEMENT_MAP.reverse.each do |k, v|
        s = s.gsub(v, k) if s.include?(v)
      end
      s
    end
  end
end