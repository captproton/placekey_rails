require 'spec_helper'
require 'rails'
require 'rails/generators'
require 'generators/placekey_rails/install/install_generator'

RSpec.describe PlacekeyRails::Generators::InstallGenerator do
  # Set up a temporary directory for testing
  let(:destination) { File.expand_path("../../../tmp", __FILE__) }
  
  before do
    # Prepare the destination directory
    FileUtils.rm_rf(destination)
    FileUtils.mkdir_p(destination)
    
    # Stub Rails.root for testing
    allow(Rails).to receive(:root).and_return(Pathname.new(destination))
  end
  
  # Helper to run the generator
  def run_generator(args = [])
    PlacekeyRails::Generators::InstallGenerator.start(args, destination_root: destination)
  end
  
  describe "initializer creation" do
    context "with default options (using credentials)" do
      before { run_generator }
      
      it "creates an initializer file using Rails credentials" do
        initializer_path = File.join(destination, "config/initializers/placekey_rails.rb")
        expect(File.exist?(initializer_path)).to be true
        
        content = File.read(initializer_path)
        expect(content).to include("Rails.application.credentials.dig(:placekey, :api_key)")
        expect(content).to include("PlacekeyRails.enable_caching(max_size: 1000)")
      end
    end
    
    context "with dotenv option" do
      before { run_generator(%w[--use_dotenv]) }
      
      it "creates an initializer using dotenv" do
        initializer_path = File.join(destination, "config/initializers/placekey_rails.rb")
        expect(File.exist?(initializer_path)).to be true
        
        content = File.read(initializer_path)
        expect(content).to include("ENV[\"PLACEKEY_API_KEY\"]")
      end
      
      it "creates .env and .env.example files" do
        env_path = File.join(destination, ".env")
        env_example_path = File.join(destination, ".env.example")
        
        expect(File.exist?(env_path)).to be true
        expect(File.exist?(env_example_path)).to be true
        
        env_content = File.read(env_path)
        expect(env_content).to include("PLACEKEY_API_KEY=your_api_key_here")
      end
    end
    
    context "with an API key" do
      before { run_generator(%w[--api_key=test_api_key]) }
      
      it "creates an initializer with the API key" do
        initializer_path = File.join(destination, "config/initializers/placekey_rails.rb")
        expect(File.exist?(initializer_path)).to be true
        
        content = File.read(initializer_path)
        expect(content).to include("PlacekeyRails.setup_client(\"test_api_key\")")
        expect(content).to include("SECURITY NOTE") # Should include security warning
      end
    end
    
    context "with skip_initializer option" do
      before { run_generator(%w[--skip_initializer]) }
      
      it "does not create an initializer" do
        initializer_path = File.join(destination, "config/initializers/placekey_rails.rb")
        expect(File.exist?(initializer_path)).to be false
      end
    end
  end
  
  describe "model handling" do
    context "when model doesn't exist" do
      before do
        # Ensure model doesn't exist
        FileUtils.rm_f(File.join(destination, "app/models/location.rb"))
        run_generator
      end
      
      it "creates a new model" do
        model_path = File.join(destination, "app/models/location.rb")
        expect(File.exist?(model_path)).to be true
        
        content = File.read(model_path)
        expect(content).to include("class Location < ApplicationRecord")
        expect(content).to include("include PlacekeyRails::Concerns::Placekeyable")
      end
      
      it "creates a migration for the new model" do
        migration_file = Dir.glob(File.join(destination, "db/migrate/*create_locations.rb")).first
        expect(migration_file).not_to be_nil
        
        content = File.read(migration_file)
        expect(content).to include("create_table :locations")
        expect(content).to include("t.string :placekey")
      end
    end
    
    context "when model exists" do
      before do
        # Create a model file
        FileUtils.mkdir_p(File.join(destination, "app/models"))
        File.write(
          File.join(destination, "app/models/location.rb"),
          "class Location < ApplicationRecord\nend"
        )
        
        # Mock column_exists? to return false
        allow_any_instance_of(PlacekeyRails::Generators::InstallGenerator)
          .to receive(:column_exists?).and_return(false)
          
        run_generator
      end
      
      it "modifies the existing model" do
        model_path = File.join(destination, "app/models/location.rb")
        content = File.read(model_path)
        expect(content).to include("include PlacekeyRails::Concerns::Placekeyable")
      end
      
      it "creates a migration to add placekey column" do
        migration_file = Dir.glob(File.join(destination, "db/migrate/*add_placekey_to_locations.rb")).first
        expect(migration_file).not_to be_nil
        
        content = File.read(migration_file)
        expect(content).to include("add_column :locations, :placekey, :string")
      end
    end
    
    context "with skip_model option" do
      before do
        # Create a model file
        FileUtils.mkdir_p(File.join(destination, "app/models"))
        File.write(
          File.join(destination, "app/models/location.rb"),
          "class Location < ApplicationRecord\nend"
        )
        
        run_generator(%w[--skip_model])
      end
      
      it "does not modify the model" do
        model_path = File.join(destination, "app/models/location.rb")
        content = File.read(model_path)
        expect(content).not_to include("include PlacekeyRails::Concerns::Placekeyable")
      end
    end
  end
  
  describe "JavaScript integration" do
    context "with application.js" do
      before do
        FileUtils.mkdir_p(File.join(destination, "app/javascript"))
        File.write(
          File.join(destination, "app/javascript/application.js"),
          "// Existing JS code"
        )
        run_generator
      end
      
      it "adds import to application.js" do
        js_path = File.join(destination, "app/javascript/application.js")
        content = File.read(js_path)
        expect(content).to include("import \"placekey_rails\"")
      end
    end
    
    context "with skip_javascript option" do
      before do
        FileUtils.mkdir_p(File.join(destination, "app/javascript"))
        File.write(
          File.join(destination, "app/javascript/application.js"),
          "// Existing JS code"
        )
        run_generator(%w[--skip_javascript])
      end
      
      it "does not add import to application.js" do
        js_path = File.join(destination, "app/javascript/application.js")
        content = File.read(js_path)
        expect(content).not_to include("import \"placekey_rails\"")
      end
    end
  end
  
  describe "custom model option" do
    before do
      run_generator(%w[--model=venue])
    end
    
    it "creates a venue model" do
      model_path = File.join(destination, "app/models/venue.rb")
      expect(File.exist?(model_path)).to be true
      
      content = File.read(model_path)
      expect(content).to include("class Venue < ApplicationRecord")
      expect(content).to include("include PlacekeyRails::Concerns::Placekeyable")
    end
    
    it "creates a migration for venues" do
      migration_file = Dir.glob(File.join(destination, "db/migrate/*create_venues.rb")).first
      expect(migration_file).not_to be_nil
      
      content = File.read(migration_file)
      expect(content).to include("create_table :venues")
    end
  end
  
  describe "combination of options" do
    before do
      run_generator(%w[--model=store --use_dotenv --skip_javascript])
    end
    
    it "creates a dotenv initializer" do
      initializer_path = File.join(destination, "config/initializers/placekey_rails.rb")
      expect(File.exist?(initializer_path)).to be true
      
      content = File.read(initializer_path)
      expect(content).to include("ENV[\"PLACEKEY_API_KEY\"]")
    end
    
    it "creates a store model" do
      model_path = File.join(destination, "app/models/store.rb")
      expect(File.exist?(model_path)).to be true
      
      content = File.read(model_path)
      expect(content).to include("include PlacekeyRails::Concerns::Placekeyable")
    end
    
    it "does not modify JavaScript" do
      # Create JS file after running generator to verify it wasn't modified
      FileUtils.mkdir_p(File.join(destination, "app/javascript"))
      File.write(
        File.join(destination, "app/javascript/application.js"),
        "// Existing JS code"
      )
      
      js_path = File.join(destination, "app/javascript/application.js")
      content = File.read(js_path)
      expect(content).not_to include("import \"placekey_rails\"")
    end
  end
end