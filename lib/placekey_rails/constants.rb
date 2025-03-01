module PlacekeyRails
  # Constants for Placekey encoding
  RESOLUTION = 10
  BASE_RESOLUTION = 12
  ALPHABET = '23456789bcdfghjkmnpqrstvwxyz'.freeze
  ALPHABET_LENGTH = ALPHABET.length
  CODE_LENGTH = 9
  TUPLE_LENGTH = 3
  PADDING_CHAR = 'a'
  REPLACEMENT_CHARS = "eu"
  REPLACEMENT_MAP = [
    ["prn", "pre"],
    ["f4nny", "f4nne"],
    ["tw4t", "tw4e"],
    ["ngr", "ngu"],
    ["dck", "dce"],
    ["vjn", "vju"],
    ["fck", "fce"],
    ["pns", "pne"],
    ["sht", "she"],
    ["kkk", "kke"],
    ["fgt", "fgu"],
    ["dyk", "dye"],
    ["bch", "bce"]
  ].freeze
end