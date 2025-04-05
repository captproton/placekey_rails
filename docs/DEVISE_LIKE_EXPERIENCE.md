# Creating a Devise-like Experience for PlacekeyRails

This document outlines how to transform the PlacekeyRails engine to provide a Devise-like developer experience with out-of-the-box functionality and progressive customization options.

## Proposed Architecture

### 1. Engine-level Mountable Controllers

Create mountable controllers within the engine namespace:

```ruby
# lib/placekey_rails/engine.rb
module PlacekeyRails
  class Engine < ::Rails::Engine
    isolate_namespace PlacekeyRails
    
    # Similar to Devise, auto-load helpers
    initializer "placekey_rails.helpers" do
      ActiveSupport.on_load(:action_controller) do
        helper PlacekeyRails::Engine.helpers
      end
    end
  end
end
```

Create controllers in the PlacekeyRails namespace:

```ruby
# app/controllers/placekey_rails/base_controller.rb
module PlacekeyRails
  class BaseController < ::ApplicationController
    layout :determine_layout
    
    private
    
    def determine_layout
      PlacekeyRails.configuration.layout || "application"
    end
    
    def placekeyable_model
      PlacekeyRails.configuration.resource_class.constantize
    end
  end
  
  # app/controllers/placekey_rails/csv_imports_controller.rb
  class CsvImportsController < BaseController
    def new
      # Show CSV import form
    end
    
    def create
      # Process CSV import
    end
    
    def template
      # Download CSV template
    end
  end
  
  # app/controllers/placekey_rails/batch_geocodes_controller.rb
  class BatchGeocodesController < BaseController
    def index
      @records = placekeyable_model.where(placekey: nil).limit(100)
    end
    
    def create
      # Process batch geocode
    end
  end
end
```

### 2. Simple Route Mounting

Add a helper method for route mounting, similar to Devise's `devise_for`:

```ruby
# lib/placekey_rails/routes.rb
module ActionDispatch::Routing
  class Mapper
    def mount_placekey_for(resource)
      resource_name = resource.to_s.pluralize
      
      scope module: 'placekey_rails' do
        get "#{resource_name}/csv_import", to: 'csv_imports#new', as: "#{resource_name}_csv_import"
        post "#{resource_name}/csv_import", to: 'csv_imports#create'
        get "#{resource_name}/csv_template", to: 'csv_imports#template', as: "#{resource_name}_csv_template"
        
        get "#{resource_name}/batch_geocode", to: 'batch_geocodes#index', as: "#{resource_name}_batch_geocode"
        post "#{resource_name}/batch_geocode", to: 'batch_geocodes#create'
      end
    end
  end
end
```

Usage in the application (just like Devise):

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount_placekey_for :locations
  resources :locations
end
```

### 3. Installation Generator

Create an installer that guides users through setup:

```ruby
# lib/generators/placekey_rails/install/install_generator.rb
module PlacekeyRails
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)
      
      def create_initializer
        template 'initializer.rb', 'config/initializers/placekey_rails.rb'
      end
      
      def mount_javascript
        if File.exist?('app/javascript/application.js')
          append_to_file 'app/javascript/application.js' do
            "\n// PlacekeyRails\nimport \"placekey_rails\"\n"
          end
        end
      end
      
      def show_readme
        readme 'README' if behavior == :invoke
      end
    end
  end
end
```

With a template initializer:

```ruby
# lib/generators/placekey_rails/install/templates/initializer.rb
PlacekeyRails.setup do |config|
  # The model that will use Placekeys
  config.resource_class = "Location"
  
  # API configuration
  config.api_key = ENV['PLACEKEY_API_KEY']
  
  # Batch operation settings
  config.batch_size = 100
  
  # View customization
  config.layout = "application" # or false to use application layout
end
```

### 4. Model Generator

Create a generator that adds Placekeyable to models:

```ruby
# lib/generators/placekey_rails/model/model_generator.rb
module PlacekeyRails
  module Generators
    class ModelGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('templates', __dir__)
      
      def create_migration
        migration_template "migration.rb", "db/migrate/add_placekey_to_#{plural_name}.rb"
      end
      
      def inject_placekeyable_concern
        if File.exist?(model_path)
          inject_into_class(model_path, class_name) do
            "  include PlacekeyRails::Concerns::Placekeyable\n\n"
          end
        else
          template "model.rb", model_path
        end
      end
      
      def update_configuration
        gsub_file "config/initializers/placekey_rails.rb", 
                 /config.resource_class = .*/, 
                 "config.resource_class = \"#{class_name}\""
      end
      
      private
      
      def model_path
        File.join("app/models", "#{file_name}.rb")
      end
    end
  end
end
```

### 5. View Templates in the Engine

Add default views to the engine that provide immediate functionality while allowing for customization when needed.

### 6. View Generator for Customization

Add a generator to extract views for customization:

```ruby
# lib/generators/placekey_rails/views/views_generator.rb
module PlacekeyRails
  module Generators
    class ViewsGenerator < Rails::Generators::Base
      source_root File.expand_path("../../../app/views/placekey_rails", __dir__)
      
      def copy_views
        directory "csv_imports", "app/views/placekey_rails/csv_imports"
        directory "batch_geocodes", "app/views/placekey_rails/batch_geocodes"
        
        puts "Copied PlacekeyRails views to app/views/placekey_rails/"
        puts "You can now customize them while maintaining the core functionality."
      end
    end
  end
end
```

### 7. Controller Generator for Customization

Allow users to override controllers for advanced customization.

### 8. JavaScript Components

Add Stimulus controllers for interactive behavior with proper namespacing to avoid conflicts.

### 9. Adding Helpers

Add helper methods for views that make common tasks simple while allowing for customization.

## Complete Integration in Application

With all these components in place, the complete integration in an application would be:

```bash
# Install the gem
bundle add placekey_rails

# Run the installer
rails generate placekey_rails:install

# Add to model
rails generate placekey_rails:model Location

# Run migrations
rails db:migrate
```

Then in routes:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount_placekey_for :locations
  resources :locations
end
```

And that's it! The application would immediately have:

- CSV import functionality at `/locations/csv_import`
- Batch geocoding at `/locations/batch_geocode`
- Default views and controllers
- JavaScript components for interactive features

For progressive customization:

```bash
# Customize views
rails generate placekey_rails:views

# Customize controllers
rails generate placekey_rails:controllers
```

## Implementation Steps

1. Create the engine namespace controllers
2. Add default views in the engine
3. Create the route helper method
4. Implement generators
5. Add JavaScript components
6. Update the example app to use the new approach
7. Document the new features

This approach would provide a Devise-like experience where developers can get started with minimal configuration while still having options for progressive customization as their needs evolve.
