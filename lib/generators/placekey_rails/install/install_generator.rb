module PlacekeyRails
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)
      
      class_option :api_key, type: :string, desc: "Your Placekey API key (optional)"
      class_option :skip_initializer, type: :boolean, default: false, desc: "Skip initializer creation"
      class_option :skip_migration, type: :boolean, default: false, desc: "Skip migration creation"
      class_option :skip_model, type: :boolean, default: false, desc: "Skip model modification"
      class_option :skip_javascript, type: :boolean, default: false, desc: "Skip JavaScript setup"
      class_option :model, type: :string, desc: "Model name to use for Placekey integration (default: location)"
      
      def create_initializer
        return if options[:skip_initializer]
        
        template "initializer.rb", "config/initializers/placekey_rails.rb"
      end
      
      def create_migration
        return if options[:skip_migration]
        
        model_name = options[:model] || "location"
        if model_exists?(model_name)
          if column_exists?(model_name, "placekey")
            say_status :skip, "Column 'placekey' already exists on #{model_name}", :yellow
          else
            @model_table_name = model_name.pluralize
            template "migration.rb", "db/migrate/#{Time.now.utc.strftime("%Y%m%d%H%M%S")}_add_placekey_to_#{@model_table_name}.rb"
          end
        else
          # Create a model and migration if it doesn't exist
          say_status :info, "Model #{model_name} doesn't exist. Creating model and migration...", :blue
          @model_name = model_name
          @model_table_name = model_name.pluralize
          template "model_migration.rb", "db/migrate/#{Time.now.utc.strftime("%Y%m%d%H%M%S")}_create_#{@model_table_name}.rb"
          template "model.rb", "app/models/#{model_name}.rb"
          return # Skip the model modification step since we're creating a new model
        end
      end
      
      def modify_model
        return if options[:skip_model]
        
        model_name = options[:model] || "location"
        model_file = "app/models/#{model_name}.rb"
        
        return unless model_exists?(model_name)
        
        if File.read(model_file).include?("PlacekeyRails::Concerns::Placekeyable")
          say_status :skip, "Model already includes Placekeyable concern", :yellow
        else
          inject_into_file model_file, after: "class #{model_name.camelize} < ApplicationRecord\n" do
            "  include PlacekeyRails::Concerns::Placekeyable\n"
          end
        end
      end
      
      def setup_javascript
        return if options[:skip_javascript]
        
        if File.exist?("app/javascript/application.js")
          import_path = "app/javascript/application.js"
          unless File.read(import_path).include?("placekey_rails")
            append_file import_path, "\n// Import PlacekeyRails JavaScript components\nimport \"placekey_rails\"\n"
          end
        elsif File.exist?("app/javascript/packs/application.js")
          import_path = "app/javascript/packs/application.js"
          unless File.read(import_path).include?("placekey_rails")
            append_file import_path, "\n// Import PlacekeyRails JavaScript components\nimport \"placekey_rails\"\n"
          end
        elsif Dir.exist?("app/javascript")
          create_file "app/javascript/placekey_rails_integration.js", "// Import PlacekeyRails JavaScript components\nimport \"placekey_rails\"\n"
          say_status :warning, "Created placekey_rails_integration.js - make sure to import it in your JavaScript entry point", :yellow
        else
          say_status :warning, "Could not find JavaScript entry point. Please add 'import \"placekey_rails\"' to your JavaScript entry file manually.", :yellow
        end
      end
      
      def print_next_steps
        if options[:skip_initializer] && options[:skip_migration] && options[:skip_model]
          say_status :info, "No changes were made. Use generator options to customize installation.", :blue
          return
        end
        
        say "\n"
        say_status :success, "PlacekeyRails has been installed! 🎉", :green
        say "\n"
        say "Next steps:", :bold
        
        unless options[:skip_migration]
          say "  1. Run migrations:"
          say "     bin/rails db:migrate"
        end
        
        unless options[:skip_initializer]
          if options[:api_key].blank?
            say "  2. Configure your Placekey API key in config/initializers/placekey_rails.rb"
          end
        end
        
        say "\n"
        say "For more information, check out the PlacekeyRails documentation:"
        say "  https://github.com/captproton/placekey_rails\n"
      end
      
      private
      
      def model_exists?(model_name)
        File.exist?(Rails.root.join("app", "models", "#{model_name}.rb"))
      end
      
      def column_exists?(model_name, column_name)
        model_class = model_name.camelize.constantize
        model_class.column_names.include?(column_name)
      rescue => e
        false
      end
    end
  end
end