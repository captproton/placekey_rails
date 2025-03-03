require 'capybara/rails'
require 'capybara/rspec'

# First try to load selenium-webdriver, but don't fail if it's not available
begin
  require 'selenium-webdriver'
  HAS_SELENIUM = true
rescue LoadError
  HAS_SELENIUM = false
  puts "Selenium WebDriver not available. Install with: bundle add selenium-webdriver"
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    if ENV['ENABLE_JS_TESTS'] && HAS_SELENIUM
      begin
        # Try to use Chrome headless
        driven_by :selenium_chrome_headless
      rescue StandardError => e
        # Fall back to rack_test if Chrome is not available
        puts "WARNING: JavaScript tests using rack_test - #{e.message}"
        driven_by :rack_test
      end
    else
      # Skip JS tests unless explicitly enabled and selenium is available
      skip "JavaScript tests disabled. Set ENABLE_JS_TESTS=true and install selenium-webdriver"
    end
  end
end

# Helper method to take screenshots
def take_screenshot(name = nil)
  return unless defined?(page) && page.respond_to?(:save_screenshot)
  
  name ||= "screenshot_#{Time.now.utc.strftime('%Y%m%d%H%M%S')}.png"
  path = File.join(Rails.root, 'tmp', name)
  page.save_screenshot(path)
  puts "Screenshot saved to #{path}"
end

# Helper for memory measurement in performance tests
class GetProcessMem
  def self.new
    require 'benchmark'
    
    obj = Object.new
    def obj.mb
      # Basic memory estimation - not as accurate as the real gem
      # but sufficient for test detection of major issues
      GC.start
      `ps -o rss= -p #{$$}`.to_i / 1024.0
    rescue
      0
    end
    
    obj
  end
end
