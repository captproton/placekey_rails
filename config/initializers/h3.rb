begin
  require 'h3'
rescue LoadError => e
  warn "H3 gem loading failed: #{e.message}"
  warn "Installing system dependencies..."
  system("brew install cmake h3") if RUBY_PLATFORM =~ /darwin/
end
