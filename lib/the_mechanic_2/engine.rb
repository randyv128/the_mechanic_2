module TheMechanic2
  class Engine < ::Rails::Engine
    isolate_namespace TheMechanic2
    
    # Engine configuration
    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: 'spec/factories'
    end
    
    # Ensure services are autoloaded
    config.autoload_paths << File.expand_path('../../app/services', __dir__)
    
    # Explicitly set view paths for the engine
    config.paths["app/views"].unshift(File.expand_path('../../app/views', __dir__))
  end
end
