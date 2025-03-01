# Installing PlacekeyRails on Digital Ocean

This guide covers the installation requirements and steps for deploying PlacekeyRails on a Digital Ocean server.

## System Requirements

### Required System Packages

```bash
# Update package list
sudo apt-get update

# Install CMake and build tools
sudo apt-get install -y cmake build-essential

# Install H3 library
sudo apt-get install -y libh3-dev
```

### Ruby Requirements
- Ruby version >= 3.2.0
- Recommended: Use `rbenv` or `rvm` for Ruby version management

### Environment Configuration

Add to `/etc/environment` or `~/.bashrc`:
```bash
export H3_DIR=/usr/local
```

## Installation

### 1. Add to your Gemfile

```ruby
gem 'placekey_rails'
```

### 2. Install the gem

```bash
bundle install
```

## JavaScript Dependencies

### Required packages:
- Node.js
- Yarn or npm

### Setup JavaScript bundling:

```bash
rails javascript:install:esbuild
```

## Production Configuration

Add to your Rails configuration:

```ruby
# filepath: config/environments/production.rb
Rails.application.configure do
  # Enable static asset serving
  config.public_file_server.enabled = true
  
  # Disable CSS compression for Tailwind
  config.assets.css_compressor = nil
end
```

## Memory Considerations

### For smaller droplets:

1. Increase swap space:
```bash
sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

2. Add swap to `/etc/fstab`:
```bash
/swapfile none swap sw 0 0
```

### Recommended Droplet Sizes:
- Minimum: 2GB RAM
- Recommended: 4GB RAM or higher for development/testing
- Production: Based on expected load

## Troubleshooting

Common issues and solutions:

1. **H3 Compilation Errors**
   - Verify cmake installation: `cmake --version`
   - Check H3 library installation: `pkg-config --libs h3`

2. **Memory Issues**
   - Monitor memory usage: `free -m`
   - Check swap usage: `swapon --show`

3. **Permission Issues**
   - Ensure proper ownership: `sudo chown -R $USER:$USER /your/app/directory`
   - Check log permissions: `sudo chmod -R 755 /your/app/log`

## Additional Resources

- [Digital Ocean Ruby on Rails Deployment Guide](https://www.digitalocean.com/community/tutorials/how-to-deploy-rails-applications)
- [H3 Documentation](https://h3geo.org/)
- [RGeo Documentation](https://github.com/rgeo/rgeo)