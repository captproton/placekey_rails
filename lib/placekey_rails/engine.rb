module PlacekeyRails
  class Engine < ::Rails::Engine
    isolate_namespace PlacekeyRails

    # Explicitly load the Placekeyable concern so it's available to models
    initializer "placekey_rails.load_concerns" do
      ActiveSupport.on_load(:active_record) do
        require_dependency File.join(PlacekeyRails::Engine.root, 'app/models/placekey_rails/concerns/placekeyable')
      end
    end

    config.generators do |g|
      g.test_framework :rspec
      g.assets false
      g.helper false
    end
  end
end