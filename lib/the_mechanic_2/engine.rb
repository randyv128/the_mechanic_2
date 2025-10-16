module TheMechanic2
  class Engine < ::Rails::Engine
    isolate_namespace TheMechanic2
    
    # Engine configuration
    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: 'spec/factories'
    end
    
    # Rails will automatically load from these paths
    # Just ensure they're in the engine's load path
    config.eager_load_paths << root.join('app', 'controllers')
    config.eager_load_paths << root.join('app', 'services')
    config.eager_load_paths << root.join('app', 'models')
  end
end
