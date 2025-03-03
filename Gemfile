source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in placekey_rails.gemspec.
gemspec

gem "puma"
gem "sqlite3"
gem "propshaft"

# Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
gem "rubocop-rails-omakase", require: false

# Start debugger with binding.b [https://github.com/ruby/debug]
# gem "debug", ">= 1.10.0"

gem "jsbundling-rails", "~> 1.3.1"
gem "stimulus-rails", "~> 1.3.4"
gem "turbo-rails", "~> 2.0.11"
gem "tailwindcss-rails", "~> 4.1"

# Use the stable version from RubyGems
gem "h3", "~> 3.7.2"

group :development, :test do
  gem "rspec-rails", "~> 7.1.1"
  gem "factory_bot_rails", "~> 6.4.4"
  gem "vcr", "~> 6.3.1"
  gem "webmock", "~> 3.25.0"
  gem "rubocop", "~> 1.73.1"
  gem "rubocop-rails", "~> 2.30.2"
  gem "rubocop-rspec", "~> 3.5.0"
  gem "yard", "~> 0.9.37"
end
