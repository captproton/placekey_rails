# PlacekeyRails Installation Guide

This guide provides detailed instructions for installing PlacekeyRails and its dependencies on various platforms.

## System Requirements

- Ruby >= 3.2.0
- Rails >= 8.0.1
- CMake (for building H3)
- H3 library (must be installed system-wide)

## macOS Installation

### Using Homebrew (recommended)

1. Install dependencies:

```bash
brew install cmake
brew install h3
```

2. Add the gem to your Gemfile:

```ruby
gem 'placekey_rails', '~> 0.2.0'
```

3. Install gems:

```bash
bundle install
```

### Using MacPorts

1. Install dependencies:

```bash
sudo port install cmake
# H3 requires manual installation from source
git clone https://github.com/uber/h3.git
cd h3
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON .
make
sudo make install
```

2. Add the gem to your Gemfile and run `bundle install`.

## Ubuntu/Debian Installation

1. Install dependencies:

```bash
sudo apt-get update
sudo apt-get install cmake build-essential
```

2. Install H3 from source:

```bash
git clone https://github.com/uber/h3.git
cd h3
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON .
make
sudo make install
sudo ldconfig
```

3. Add the gem to your Gemfile and run `bundle install`.

## CentOS/RHEL Installation

1. Install dependencies:

```bash
sudo yum install cmake gcc gcc-c++ make
```

2. Install H3 from source:

```bash
git clone https://github.com/uber/h3.git
cd h3
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON .
make
sudo make install
sudo ldconfig
```

3. Add the gem to your Gemfile and run `bundle install`.

## Windows Installation

Windows support is limited and requires Windows Subsystem for Linux (WSL). We recommend using WSL with Ubuntu for the best experience.

1. Install WSL by following Microsoft's [official guide](https://learn.microsoft.com/en-us/windows/wsl/install).

2. Inside WSL, follow the Ubuntu installation instructions above.

## Docker Installation

If you're using Docker, you can add the necessary dependencies to your Dockerfile:

```dockerfile
# Use a base Ruby image
FROM ruby:3.2-alpine

# Install build dependencies
RUN apk add --no-cache build-base cmake git

# Install H3
RUN git clone https://github.com/uber/h3.git && \
    cd h3 && \
    cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON . && \
    make && \
    make install && \
    cd .. && \
    rm -rf h3

# Continue with your Rails app setup...
```

## Heroku Installation

For Heroku deployment, you'll need to use buildpacks to install the H3 library:

1. Add the apt buildpack:

```bash
heroku buildpacks:add --index 1 heroku-community/apt
```

2. Create an `Aptfile` in your project root:

```
cmake
build-essential
```

3. Add a custom buildpack script for H3:

Create a file at `.buildpacks/install_h3.sh`:

```bash
#!/bin/bash
echo "-----> Installing H3 library"
cd /tmp
git clone https://github.com/uber/h3.git
cd h3
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON .
make
make install
echo "-----> H3 installation complete"
```

Then set up a custom buildpack that runs this script.

## Digital Ocean App Platform

For DigitalOcean App Platform, additional configuration is needed. See [DIGITAL_OCEAN_INSTALLATION.md](DIGITAL_OCEAN_INSTALLATION.md) for detailed instructions.

## Troubleshooting Installation Issues

### Missing H3 Library

If you see an error like "cannot load such file -- h3" or issues calling H3 functions, make sure:

1. The H3 library is properly installed:

```bash
# Check for H3 library files
ls -la /usr/local/lib/libh3*
```

2. The library is in your load path:

```bash
# Add to LD_LIBRARY_PATH if needed
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
```

3. You might need to reinstall the h3 gem:

```bash
gem uninstall h3
bundle install
```

### Ruby Version Compatibility

If you're seeing errors related to Ruby version compatibility, make sure you're using Ruby 3.2.0 or later:

```bash
ruby -v
```

If you need to upgrade, use your preferred version manager:

```bash
# Using RVM
rvm install 3.2.0
rvm use 3.2.0

# Using rbenv
rbenv install 3.2.0
rbenv local 3.2.0
```

### Bundler Platform Issues

If bundler complains about platform compatibility, add the necessary platforms to your Gemfile.lock:

```bash
bundle lock --add-platform x86_64-linux
bundle lock --add-platform arm64-darwin
```

### CMake Not Found

If you're getting errors about CMake not being found, make sure it's installed:

```bash
cmake --version
```

If not installed, install it using your package manager as shown in the platform-specific instructions above.

## Verifying Installation

After installation, verify that everything is working correctly:

```ruby
# In Rails console (rails c)
require 'placekey_rails'
PlacekeyRails.geo_to_placekey(37.7371, -122.44283)
# Should return a valid Placekey like "@5vg-82n-kzz"
```

If this works without errors, your installation is successful.
