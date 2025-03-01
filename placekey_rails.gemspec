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
  spec.test_files = Dir["spec/**/*"]
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.0.1"
  spec.add_dependency "h3", "~> 3.7.2"  # Latest H3 from master branch
  spec.add_dependency "rgeo", '~> 3.0', '>= 3.0.1'        # For spatial operations
  spec.add_dependency "rgeo-geojson", "~> 2.2.0"  # For GeoJSON support
  spec.add_dependency "httparty", "~> 0.22.0"   # For API calls
  spec.add_dependency "rover-df", "~> 0.4.1"      # For DataFrame operations (similar to pandas)

  spec.requirements << 'cmake'
  spec.requirements << 'h3'
  spec.required_ruby_version = '>= 3.2.0'

  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'capybara'

  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'guard-rails'

  spec.add_development_dependency 'puma'
  spec.add_development_dependency 'pry-doc'
  spec.add_development_dependency 'pry-rails'
  spec.add_development_dependency 'awesome_print'
  spec.add_development_dependency 'binding_of_caller'

  spec.add_dependency 'jsbundling-rails'
  spec.add_dependency 'stimulus-rails'
  spec.add_dependency 'turbo-rails'

  spec.add_dependency 'tailwindcss-rails'
end
