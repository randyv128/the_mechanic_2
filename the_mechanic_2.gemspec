require_relative "lib/the_mechanic_2/version"

Gem::Specification.new do |spec|
  spec.name        = "the_mechanic_2"
  spec.version     = TheMechanic2::VERSION
  spec.authors     = [ "mrpandapants" ]
  spec.email       = [ "villanuevarandy237@gmail.com" ]
  spec.homepage    = "https://github.com/randyv128/the_mechanic_2"
  spec.summary     = "Ruby code benchmarking engine for Rails applications"
  spec.description = "The Mechanic 2 is a Rails Engine that provides Ruby code benchmarking capabilities within any Rails application, with full access to your application's classes and dependencies."
  spec.license     = "MIT"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/randyv128/the_mechanic_2"
  spec.metadata["changelog_uri"] = "https://github.com/randyv128/the_mechanic_2/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 6.0"
  spec.add_dependency "benchmark-ips", "~> 2.0"
  spec.add_dependency "memory_profiler", "~> 1.0"
  
  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "sqlite3", "~> 1.4"
  spec.add_development_dependency "rails-controller-testing"
end
