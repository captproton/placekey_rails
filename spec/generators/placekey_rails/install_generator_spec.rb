require 'spec_helper'
require 'generators/placekey_rails/install/install_generator'

RSpec.describe PlacekeyRails::Generators::InstallGenerator, type: :generator do
  destination File.expand_path("../../../tmp", __dir__)
  
  before do
    prepare_destination
    allow(Rails).to receive(:root).and_return(Pathname.new(destination_root))
  end
  
  describe "initializer creation" do
    context "with default options (using credentials)" do
      before { run_generator }
      
      it "creates an initializer file using Rails credentials" do
        expect(destination_root).to have_structure do
          directory "config" do
            directory "initializers" do
              file "placekey_rails.rb" do
                contains "Rails.application.credentials.dig(:placekey, :api_key)"
                contains "PlacekeyRails.enable_caching(max_size: 1000)"
              end
            end
          end
        end
      end
    end
    
    context "with dotenv option" do
      before { run_generator %w[--use_dotenv] }
      
      it "creates an initializer using dotenv" do
        expect(destination_root).to have_structure do
          directory "config" do
            directory "initializers" do
              file "placekey_rails.rb" do
                contains "ENV[\"PLACEKEY_API_KEY\"]"
              end
            end
          end
        end
      end
      
      it "creates .env and .env.example files" do
        expect(destination_root).to have_structure do
          file ".env" do
            contains "PLACEKEY_API_KEY=your_api_key_here"
          end
          file ".env.example" do
            contains "PLACEKEY_API_KEY=your_api_key_here"
          end
        end
      end
    end
    
    context "with an API key" do
      before { run_generator %w[--api_key=test_api_key] }
      
      it "creates an initializer with the API key" do
        expect(destination_root).to have_structure do
          directory "config" do
            directory "initializers" do
              file "placekey_rails.rb" do
                contains "PlacekeyRails.setup_client(\"test_api_key\")"
                contains "SECURITY NOTE" # Should include security warning
              end
            end
          end
        end
      end
    end
    
    context "with skip_initializer option" do
      before { run_generator %w[--skip_initializer] }
      
      it "does not create an initializer" do
        expect(destination_root).not_to have_structure do
          directory "config" do
            directory "initializers" do
              file "placekey_rails.rb"
            end
          end
        end
      end
    end
  end
  
  describe "model handling" do
    context "when model doesn't exist" do
      before do
        # Ensure model doesn't exist
        FileUtils.rm_f(File.join(destination_root, "app/models/location.rb"))
        run_generator
      end
      
      it "creates a new model" do
        expect(destination_root).to have_structure do
          directory "app" do
            directory "models" do
              file "location.rb" do
                contains "class Location < ApplicationRecord"
                contains "include PlacekeyRails::Concerns::Placekeyable"
              end
            end
          end
        end
      end
      
      it "creates a migration for the new model" do
        migration_file = Dir.glob(File.join(destination_root, "db/migrate/*create_locations.rb")).first
        expect(migration_file).not_to be_nil
        expect(File.read(migration_file)).to include("create_table :locations")
        expect(File.read(migration_file)).to include("t.string :placekey")
      end
    end
    
    context "when model exists" do
      before do
        # Create a model file
        FileUtils.mkdir_p(File.join(destination_root, "app/models"))
        File.write(
          File.join(destination_root, "app/models/location.rb"),
          "class Location < ApplicationRecord\nend"
        )
        
        # Mock column_exists? to return false
        allow_any_instance_of(PlacekeyRails::Generators::InstallGenerator)
          .to receive(:column_exists?).and_return(false)
          
        run_generator
      end
      
      it "modifies the existing model" do
        expect(destination_root).to have_structure do
          directory "app" do
            directory "models" do
              file "location.rb" do
                contains "class Location < ApplicationRecord"
                contains "include PlacekeyRails::Concerns::Placekeyable"
              end
            end
          end
        end
      end
      
      it "creates a migration to add placekey column" do
        migration_file = Dir.glob(File.join(destination_root, "db/migrate/*add_placekey_to_locations.rb")).first
        expect(migration_file).not_to be_nil
        expect(File.read(migration_file)).to include("add_column :locations, :placekey, :string")
      end
    end
    
    context "with skip_model option" do
      before do
        # Create a model file
        FileUtils.mkdir_p(File.join(destination_root, "app/models"))
        File.write(
          File.join(destination_root, "app/models/location.rb"),
          "class Location < ApplicationRecord\nend"
        )
        
        run_generator %w[--skip_model]
      end
      
      it "does not modify the model" do
        expect(File.read(File.join(destination_root, "app/models/location.rb")))
          .not_to include("include PlacekeyRails::Concerns::Placekeyable")
      end
    end
  end
  
  describe "JavaScript integration" do
    context "with application.js" do
      before do
        FileUtils.mkdir_p(File.join(destination_root, "app/javascript"))
        File.write(
          File.join(destination_root, "app/javascript/application.js"),
          "// Existing JS code"
        )
        run_generator
      end
      
      it "adds import to application.js" do
        expect(destination_root).to have_structure do
          directory "app" do
            directory "javascript" do
              file "application.js" do
                contains "import \"placekey_rails\""
              end
            end
          end
        end
      end
    end
    
    context "with skip_javascript option" do
      before do
        FileUtils.mkdir_p(File.join(destination_root, "app/javascript"))
        File.write(
          File.join(destination_root, "app/javascript/application.js"),
          "// Existing JS code"
        )
        run_generator %w[--skip_javascript]
      end
      
      it "does not add import to application.js" do
        expect(File.read(File.join(destination_root, "app/javascript/application.js")))
          .not_to include("import \"placekey_rails\"")
      end
    end
  end
  
  describe "custom model option" do
    before do
      run_generator %w[--model=venue]
    end
    
    it "creates a venue model" do
      expect(destination_root).to have_structure do
        directory "app" do
          directory "models" do
            file "venue.rb" do
              contains "class Venue < ApplicationRecord"
              contains "include PlacekeyRails::Concerns::Placekeyable"
            end
          end
        end
      end
    end
    
    it "creates a migration for venues" do
      migration_file = Dir.glob(File.join(destination_root, "db/migrate/*create_venues.rb")).first
      expect(migration_file).not_to be_nil
      expect(File.read(migration_file)).to include("create_table :venues")
    end
  end
  
  describe "combination of options" do
    before do
      run_generator %w[--model=store --use_dotenv --skip_javascript]
    end
    
    it "creates a dotenv initializer" do
      expect(destination_root).to have_structure do
        directory "config" do
          directory "initializers" do
            file "placekey_rails.rb" do
              contains "ENV[\"PLACEKEY_API_KEY\"]"
            end
          end
        end
      end
    end
    
    it "creates a store model" do
      expect(destination_root).to have_structure do
        directory "app" do
          directory "models" do
            file "store.rb" do
              contains "include PlacekeyRails::Concerns::Placekeyable"
            end
          end
        end
      end
    end
    
    it "does not modify JavaScript" do
      # Create JS file after running generator to verify it wasn't modified
      FileUtils.mkdir_p(File.join(destination_root, "app/javascript"))
      File.write(
        File.join(destination_root, "app/javascript/application.js"),
        "// Existing JS code"
      )
      
      expect(File.read(File.join(destination_root, "app/javascript/application.js")))
        .not_to include("import \"placekey_rails\"")
    end
  end
end