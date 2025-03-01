require_relative "lib/placekey_rails/version"

Gem::Specification.new do |spec|
  spec.name        = "placekey_rails"
  spec.version     = PlacekeyRails::VERSION
  spec.authors     = [ "captproton" ]
  spec.email       = [ "carl@wdwhub.net" ]
  spec.homepage    = "https://github.com/captproton/placekey_rails"
  spec.summary     = "Ruby on Rails engine for working with Placekeys" 
  spec.description = "A Ruby on Rails engine that provides functionality for converting between Placekeys and geographic coordinates, H3 indices, and performing spatial operations."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/captproton/placekey_rails"
  spec.metadata["changelog_uri"] = "https://github.com/captproton/placekey_rails/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.0.1"
end
