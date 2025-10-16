require "the_mechanic_2/version"
require "the_mechanic_2/configuration"
require "the_mechanic_2/engine"

module TheMechanic2
  # Explicitly autoload all classes to work with both eager_load and autoload
  autoload :ApplicationController, 'the_mechanic_2/application_controller'
  autoload :BenchmarksController, 'the_mechanic_2/benchmarks_controller'
  
  autoload :BenchmarkService, 'the_mechanic_2/benchmark_service'
  autoload :RailsRunnerService, 'the_mechanic_2/rails_runner_service'
  autoload :SecurityService, 'the_mechanic_2/security_service'
  
  autoload :BenchmarkRequest, 'the_mechanic_2/benchmark_request'
  autoload :BenchmarkResult, 'the_mechanic_2/benchmark_result'
  
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  self.configuration = Configuration.new
end
