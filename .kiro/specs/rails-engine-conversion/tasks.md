# Implementation Plan

- [x] 1. Generate Rails Engine structure and configure gemspec
  - Use `rails plugin new the_mechanic --mountable` to generate engine skeleton
  - Configure gemspec with dependencies (benchmark-ips, memory_profiler)
  - Set up namespace isolation in engine.rb
  - Create version.rb with initial version number
  - _Requirements: 1.1, 1.2, 1.3_

- [ ] 2. Implement configuration system
  - [x] 2.1 Create Configuration class with timeout, authentication options
    - Write TheMechanic::Configuration class with attr_accessors
    - Implement module-level configure method and configuration accessor
    - Set sensible defaults (timeout: 30, enable_authentication: false)
    - _Requirements: 4.2, 4.3, 4.4, 4.5_
  
  - [x] 2.2 Write unit tests for configuration
    - Test default values
    - Test configuration block syntax
    - Test configuration persistence
    - _Requirements: 4.2, 4.3, 4.4, 4.5_

- [ ] 3. Create security validation service
  - [x] 3.1 Implement SecurityService with code validation
    - Write validate method that checks for forbidden patterns
    - Define forbidden patterns (system calls, file ops, network, database writes)
    - Return structured validation result with errors array
    - _Requirements: 7.1, 7.4, 7.6_
  
  - [x] 3.2 Write comprehensive security tests
    - Test detection of system calls (system, exec, spawn, backticks)
    - Test detection of file operations (File.open, File.read, File.write)
    - Test detection of network operations (Net::HTTP, Socket)
    - Test detection of database write operations (save, update, destroy, create)
    - Test that safe operations pass validation
    - _Requirements: 7.1, 7.4, 7.6_

- [ ] 4. Implement RailsRunnerService for process spawning
  - [x] 4.1 Create RailsRunnerService with script generation
    - Write create_script method that generates temporary Ruby script
    - Include shared_setup code in script
    - Include benchmark code with benchmark-ips and memory_profiler
    - Add JSON serialization of results to script
    - Add error handling and JSON error output to script
    - _Requirements: 3.1, 3.2, 3.3, 7.1_
  
  - [x] 4.2 Implement process spawning with rails runner
    - Write execute method that creates temp script file
    - Spawn rails runner process using Open3.capture3
    - Pass timeout parameter to capture3
    - Capture stdout and stderr separately
    - Parse JSON output from runner process
    - Clean up temporary files using Tempfile
    - _Requirements: 3.1, 3.2, 3.3, 7.5_
  
  - [x] 4.3 Add error handling and timeout management
    - Handle timeout errors from Open3.capture3
    - Parse and format errors from runner process
    - Handle JSON parsing errors
    - Ensure temp files are cleaned up even on errors
    - _Requirements: 7.5, 7.8_
  
  - [x] 4.4 Write RailsRunnerService tests
    - Test successful script generation
    - Test successful process spawning and result parsing
    - Test timeout enforcement
    - Test error handling for invalid code
    - Test temp file cleanup
    - _Requirements: 3.1, 3.2, 3.3, 7.5_

- [ ] 5. Implement core BenchmarkService orchestration
  - [x] 5.1 Create BenchmarkService with run method
    - Write run method that accepts shared_setup, code_a, code_b, timeout
    - Instantiate RailsRunnerService
    - Execute code_a using RailsRunnerService
    - Execute code_b using RailsRunnerService
    - Call format_results to create BenchmarkResult
    - _Requirements: 2.1, 2.2, 3.1, 3.2, 3.3_
  
  - [x] 5.2 Implement result formatting
    - Write format_results method
    - Calculate winner based on IPS comparison
    - Calculate performance_ratio
    - Aggregate logs from both runs
    - Create and return BenchmarkResult instance
    - _Requirements: 2.4_
  
  - [x] 5.3 Write BenchmarkService tests
    - Test successful benchmark orchestration
    - Test result formatting and winner calculation
    - Test performance ratio calculation
    - Test integration with RailsRunnerService
    - _Requirements: 2.1, 2.2, 2.4, 3.1, 3.2, 3.3_

- [ ] 6. Create data models for requests and results
  - [x] 6.1 Implement BenchmarkRequest model
    - Write validation for required fields (code_a, code_b)
    - Validate timeout range (1-300 seconds)
    - Provide clean interface for request data
    - _Requirements: 2.3_
  
  - [x] 6.2 Implement BenchmarkResult model
    - Format benchmark results with code_a_metrics and code_b_metrics
    - Calculate winner and performance_ratio
    - Implement to_json export method
    - Implement to_markdown export method
    - _Requirements: 2.4, 2.5_
  
  - [x] 6.3 Write model tests
    - Test BenchmarkRequest validation
    - Test BenchmarkResult formatting
    - Test winner calculation logic
    - Test export methods (JSON and Markdown)
    - _Requirements: 2.3, 2.4, 2.5_

- [ ] 7. Build BenchmarksController with all endpoints
  - [x] 7.1 Create controller with index action
    - Generate namespaced controller (TheMechanic::BenchmarksController)
    - Implement index action that renders main view
    - Add helper methods for asset inlining (inline_css, inline_javascript)
    - _Requirements: 1.2, 5.1, 5.2, 5.3_
  
  - [x] 7.2 Implement validate endpoint
    - Create POST /validate action
    - Call SecurityService to validate code
    - Return JSON with validation result
    - _Requirements: 2.6, 7.1_
  
  - [x] 7.3 Implement run endpoint
    - Create POST /run action
    - Validate request parameters using BenchmarkRequest
    - Call SecurityService before execution
    - Call BenchmarkService to execute benchmark
    - Return formatted results using BenchmarkResult
    - Handle errors and return appropriate status codes
    - _Requirements: 2.1, 2.2, 2.3, 7.1, 7.5, 7.6_
  
  - [x] 7.4 Implement export endpoint
    - Create POST /export action
    - Accept results and format parameter (json or markdown)
    - Return formatted export data
    - _Requirements: 2.5_
  
  - [x] 7.5 Add authentication support
    - Implement before_action for authentication check
    - Call configuration authentication_callback if enabled
    - Return 401 if authentication fails
    - _Requirements: 4.4_
  
  - [x] 7.6 Write controller tests
    - Test index action renders view with inlined assets
    - Test validate endpoint with valid and invalid code
    - Test run endpoint with successful benchmarks
    - Test run endpoint error handling
    - Test export endpoint with both formats
    - Test authentication callback integration
    - _Requirements: 1.2, 2.1, 2.5, 2.6, 4.4, 5.1, 5.2, 5.3, 7.1_

- [x] 8. Configure engine routes
  - Define routes in config/routes.rb within TheMechanic::Engine.routes.draw
  - Map root to benchmarks#index
  - Map POST /validate to benchmarks#validate
  - Map POST /run to benchmarks#run
  - Map POST /export to benchmarks#export
  - _Requirements: 1.2_

- [ ] 9. Create CSS assets matching original Mechanic design
  - [x] 9.1 Write application.css with complete styling
    - Create app/assets/stylesheets/the_mechanic/application.css
    - Implement layout styles (header, main content, footer)
    - Style code editor containers
    - Style buttons and form controls
    - Style results display (metric cards, winner indicator)
    - Style runtime logs panel
    - Add responsive breakpoints for mobile/tablet/desktop
    - Match color scheme and typography from original Mechanic
    - _Requirements: 5.5, 5.6_

- [ ] 10. Create JavaScript for UI functionality
  - [x] 10.1 Write application.js with Monaco Editor integration
    - Create app/assets/javascripts/the_mechanic/application.js
    - Initialize Monaco Editor for three code inputs (shared_setup, code_a, code_b)
    - Configure Monaco with Ruby syntax highlighting
    - _Requirements: 5.5_
  
  - [x] 10.2 Implement form handling and API calls
    - Add event listeners for validate and run buttons
    - Implement fetch calls to /validate and /run endpoints
    - Handle loading states and disable buttons during execution
    - Display validation errors inline
    - _Requirements: 2.6_
  
  - [x] 10.3 Implement results rendering
    - Parse benchmark results from API response
    - Render side-by-side comparison with metric cards
    - Display winner indicator with performance ratio
    - Show all metrics (IPS, stddev, objects, memory, time)
    - _Requirements: 2.4_
  
  - [x] 10.4 Implement runtime logs display
    - Create collapsible logs panel
    - Render logs in tabbed interface (Summary, Benchmark, Memory, GC)
    - Format log content for readability
    - _Requirements: 2.4_
  
  - [x] 10.5 Implement export functionality
    - Add export buttons for JSON and Markdown
    - Call /export endpoint with results data
    - Trigger download of exported file
    - Add copy-to-clipboard functionality
    - Show visual feedback on copy
    - _Requirements: 2.5_
  
  - [x] 10.6 Add error handling and user feedback
    - Display error messages from API responses
    - Show timeout errors clearly
    - Handle network errors gracefully
    - Provide reset functionality to clear form and results
    - _Requirements: 2.4_

- [x] 11. Create main view template with asset inlining
  - Create app/views/the_mechanic/benchmarks/index.html.erb
  - Build HTML structure matching original Mechanic layout
  - Add style tag with <%= inline_css %> helper call
  - Add script tag with <%= inline_javascript %> helper call
  - Include div containers for app mounting
  - Ensure no external asset references (all inline)
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

- [ ] 12. Set up dummy Rails application for testing
  - [x] 12.1 Configure dummy app in spec/dummy
    - Ensure dummy app is generated with engine
    - Mount engine at /ask_the_mechanic in dummy routes
    - Create sample ActiveRecord model (User) for testing context access
    - Configure database (SQLite for simplicity)
    - _Requirements: 6.1, 6.2, 6.3_
  
  - [x] 12.2 Write integration tests using dummy app
    - Test engine mounting and route accessibility
    - Test access to dummy app's User model from benchmark code
    - Test full request/response cycle
    - Test UI rendering with inlined assets
    - _Requirements: 1.2, 1.4, 3.1, 3.2, 3.3, 6.1, 6.2, 6.3_

- [ ] 13. Write comprehensive documentation
  - [x] 13.1 Create README.md with installation and usage
    - Document gem installation (Gemfile entry)
    - Show route mounting example with /ask_the_mechanic
    - Emphasize zero-setup requirement (just gem + route)
    - Provide configuration examples
    - Include example benchmark snippets using Rails models
    - Add troubleshooting section
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_
  
  - [x] 13.2 Add inline code documentation
    - Document all public methods with YARD comments
    - Add usage examples in comments
    - Document configuration options
    - _Requirements: 8.4_

- [ ] 14. Final integration and polish
  - [x] 14.1 Test complete workflow end-to-end
    - Install gem in dummy app
    - Access /ask_the_mechanic
    - Run benchmarks using dummy app models
    - Verify all features work (validate, run, export)
    - Test authentication callback
    - Verify asset inlining (no external requests)
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 4.2, 4.3, 4.4, 4.5, 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 7.1, 7.2, 7.3, 7.4, 7.5, 7.6_
  
  - [x] 14.2 Performance and security audit
    - Verify timeout protection works
    - Test all forbidden operations are blocked
    - Check asset inline performance
    - Verify no memory leaks
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6_
  
  - [x] 14.3 Cross-browser testing
    - Test UI in Chrome, Firefox, Safari
    - Verify Monaco Editor works in all browsers
    - Check responsive design on mobile
    - _Requirements: 5.5_
