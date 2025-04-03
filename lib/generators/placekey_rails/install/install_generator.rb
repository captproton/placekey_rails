require "rails/generators"
require "rails/generators/base"

module PlacekeyRails
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      class_option :api_key, type: :string, desc: "Your Placekey API key (not recommended, use credentials instead)"
      class_option :use_dotenv, type: :boolean, default: false, desc: "Configure to use dotenv instead of credentials"
      class_option :skip_initializer, type: :boolean, default: false, desc: "Skip initializer creation"
      class_option :skip_migration, type: :boolean, default: false, desc: "Skip migration creation"
      class_option :skip_model, type: :boolean, default: false, desc: "Skip model modification"
      class_option :skip_javascript, type: :boolean, default: false, desc: "Skip JavaScript setup"
      class_option :model, type: :string, desc: "Model name to use for Placekey integration (default: location)"

      def create_initializer
        return if options[:skip_initializer]

        template "initializer.rb", "config/initializers/placekey_rails.rb"
      end

      def setup_credentials
        return if options[:skip_initializer] || options[:api_key].present? || options[:use_dotenv]

        say_status :info, "To add your Placekey API key to credentials, run:", :blue
        say "\n  rails credentials:edit\n"
        say "Then add this to your credentials file:"
        say <<~YAML

          placekey:
            api_key: your_api_key_here
        YAML
      end

      def setup_dotenv
        return if options[:skip_initializer] || options[:api_key].present? || !options[:use_dotenv]

        unless File.exist?(Rails.root.join(".env"))
          template "dotenv", ".env"
        end

        unless File.exist?(Rails.root.join(".env.example"))
          template "dotenv.example", ".env.example"
        end

        unless gem_installed?("dotenv-rails")
          say_status :warning, "Please add dotenv-rails to your Gemfile:", :yellow
          say "\n  gem 'dotenv-rails', groups: [:development, :test, :production]\n"
          say "Then run: bundle install"
        end
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
          nil # Skip the model modification step since we're creating a new model
        end
      end

      def modify_model
        return if options[:skip_model]

        model_name = options[:model] || "location"
        model_file = "app/models/#{model_name}.rb"

        return unless model_exists?(model_name)

        begin
          content = File.read(model_file)
          return if content.include?("PlacekeyRails::Concerns::Placekeyable")

          inject_into_file model_file, after: "class #{model_name.camelize} < ApplicationRecord\n" do
            "  include PlacekeyRails::Concerns::Placekeyable\n"
          end
        rescue Errno::ENOENT
          say_status :error, "Could not read #{model_file}", :red
        end
      end

      def setup_javascript
        return if options[:skip_javascript]

        # Handle application.js
        if File.exist?(File.join(destination_root, "app/javascript/application.js"))
          js_file = File.join(destination_root, "app/javascript/application.js")
          current_content = File.read(js_file)

          # Only append if import doesn't already exist
          unless current_content.include?("placekey_rails")
            new_content = current_content + "\n// Import PlacekeyRails JavaScript components\nimport \"placekey_rails\"\n"
            # Write the file directly instead of using append_file
            File.write(js_file, new_content)
          end

        # Handle packs/application.js
        elsif File.exist?(File.join(destination_root, "app/javascript/packs/application.js"))
          js_file = File.join(destination_root, "app/javascript/packs/application.js")
          current_content = File.read(js_file)

          # Only append if import doesn't already exist
          unless current_content.include?("placekey_rails")
            new_content = current_content + "\n// Import PlacekeyRails JavaScript components\nimport \"placekey_rails\"\n"
            # Write the file directly instead of using append_file
            File.write(js_file, new_content)
          end

        # Handle directories without js files
        elsif Dir.exist?(File.join(destination_root, "app/javascript"))
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

        say "\n"
        say "For more information, check out the PlacekeyRails documentation:"
        say "  https://github.com/captproton/placekey_rails\n"
      end

      private

      def model_exists?(model_name)
        File.exist?(Rails.root.join("app", "models", "#{model_name}.rb"))
      rescue
        false
      end

      def column_exists?(model_name, column_name)
        # For testing, just assume column doesn't exist
        if defined?(Rails::Generators::Testing)
          false
        else
          begin
            model_class = model_name.camelize.constantize
            model_class.column_names.include?(column_name)
          rescue => e
            false
          end
        end
      end

      def gem_installed?(gem_name)
        Gem::Specification.find_all_by_name(gem_name).any?
      end
    end
  end
end
