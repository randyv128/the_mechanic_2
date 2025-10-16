# frozen_string_literal: true

module TheMechanic2
  # Configuration class for The Mechanic engine
  # Allows customization of timeout, authentication, and other settings
  class Configuration
    # Maximum execution time for benchmarks in seconds
    attr_accessor :timeout
    
    # Whether to require authentication before allowing benchmark execution
    attr_accessor :enable_authentication
    
    # Proc/lambda to call for authentication check
    # Should accept a controller instance and return true/false
    attr_accessor :authentication_callback
    
    def initialize
      @timeout = 30 # seconds
      @enable_authentication = false
      @authentication_callback = nil
    end
  end
  
  class << self
    # Returns the global configuration instance
    def configuration
      @configuration ||= Configuration.new
    end
    
    # Yields the configuration instance for block-style configuration
    # @example
    #   TheMechanic2.configure do |config|
    #     config.timeout = 60
    #     config.enable_authentication = true
    #   end
    def configure
      yield(configuration)
    end
    
    # Resets configuration to defaults (useful for testing)
    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
