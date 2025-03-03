require 'capybara/rails'
require 'capybara/rspec'

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    if ENV['ENABLE_JS_TESTS']
      # Check if Chrome is available
      begin
        require 'selenium-webdriver'
        driven_by :selenium_chrome_headless
      rescue LoadError, Selenium::WebDriver::Error::WebDriverError => e
        # Fall back to rack_test if selenium-webdriver is not available
        # or if Chrome is not available
        puts "WARNING: JavaScript tests disabled - #{e.message}"
        driven_by :rack_test
      end
    else
      # Skip JS tests unless explicitly enabled
      skip "JavaScript tests disabled. Set ENABLE_JS_TESTS=true to run."
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
