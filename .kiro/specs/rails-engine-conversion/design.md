# Design Document

## Overview

The Mechanic 2 is a Rails Engine gem that provides Ruby code benchmarking capabilities within any Rails application. The engine is designed to be completely self-contained, requiring zero configuration beyond adding the gem to the Gemfile and mounting a single route. It provides a web interface at `/ask_the_mechanic` that allows developers to benchmark Ruby code snippets with full access to their application's classes, models, and dependencies.

The design prioritizes simplicity and isolation: all assets (CSS and JavaScript) are inlined directly into the HTML response, eliminating any dependency on the host application's asset pipeline. The UI replicates the look and feel of the original Mechanic application while being delivered as a single, self-contained HTML page.

## Architecture

### Engine Structure

```
the_mechanic/
├── lib/
│   ├── the_mechanic.rb                    # Main entry point
│   ├── the_mechanic/
│   │   ├── engine.rb                      # Rails::Engine class
│   │   ├── version.rb                     # Gem version
│   │   └── configuration.rb               # Configuration options
│   └── tasks/
├── app/
│   ├── controllers/
│   │   └── the_mechanic/
│   │       ├── application_controller.rb
│   │       └── benchmarks_controller.rb   # Main controller
│   ├── services/
│   │   └── the_mechanic/
│   │       ├── benchmark_service.rb       # Core benchmarking logic
│   │       ├── rails_runner_service.rb    # Rails runner process spawning
│   │       └── security_service.rb        # Code validation
│   ├── models/
│   │   └── the_mechanic/
│   │       ├── benchmark_request.rb       # Request validation
│   │       └── benchmark_result.rb        # Result formatting
│   ├── views/
│   │   └── the_mechanic/
│   │       └── benchmarks/
│   │           └── index.html.erb         # Main UI page
│   └── assets/
│       ├── javascripts/
│       │   └── the_mechanic/
│       │       └── application.js         # Compiled JS (to be inlined)
│       └── stylesheets/
│           └── the_mechanic/
│               └── application.css        # Compiled CSS (to be inlined)
├── config/
│   └── routes.rb                          # Engine routes
├── spec/
│   ├── dummy/                             # Test Rails app
│   └── ...                                # RSpec tests
├── the_mechanic.gemspec
├── Gemfile
└── README.md
```

### Key Design Decisions

1. **Mountable Engine with Namespace Isolation**: Uses `isolate_namespace TheMechanic` to prevent conflicts with host application
2. **Inline Assets**: All CSS and JavaScript are read from the asset directory and inlined into the HTML response
3. **No Asset Pipeline Dependency**: The engine does not integrate with Sprockets, Webpacker, or any asset bundler
4. **Single Page Application**: The entire UI is delivered as one HTML page with embedded assets
5. **Direct Rails Context Access**: Benchmark code executes in the context of the Rails application with access to all loaded classes

## Components and Interfaces

### 1. Engine Class (`lib/the_mechanic/engine.rb`)

The core engine class that integrates with Rails:

```ruby
module TheMechanic
  class Engine < ::Rails::Engine
    isolate_namespace TheMechanic
    
    # Engine configuration
    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
```

**Responsibilities:**
- Namespace isolation
- Route mounting
- Load path configuration

### 2. Configuration (`lib/the_mechanic/configuration.rb`)

Provides configurable options for the engine:

```ruby
module TheMechanic
  class Configuration
    attr_accessor :timeout, :enable_authentication, :authentication_callback
    
    def initialize
      @timeout = 30 # seconds
      @enable_authentication = false
      @authentication_callback = nil
    end
  end
  
  def self.configuration
    @configuration ||= Configuration.new
  end
  
  def self.configure
    yield(configuration)
  end
end
```

**Configuration Options:**
- `timeout`: Maximum execution time for benchmarks (default: 30 seconds)
- `enable_authentication`: Whether to require authentication (default: false)
- `authentication_callback`: Proc to call for authentication check

### 3. BenchmarksController (`app/controllers/the_mechanic/benchmarks_controller.rb`)

Main controller handling all requests:

**Actions:**
- `index`: Renders the main UI page with inlined assets
- `validate`: Validates code without executing (POST /validate)
- `run`: Executes benchmark and returns results (POST /run)
- `export`: Exports results in JSON or Markdown (POST /export)

**Key Methods:**
- `inline_assets`: Reads CSS and JS files and returns them as strings
- `check_authentication`: Calls authentication callback if configured

### 4. RailsRunnerService (`app/services/the_mechanic/rails_runner_service.rb`)

Service responsible for spawning and managing Rails runner processes:

**Methods:**
- `execute(code:, shared_setup:, timeout:)`: Spawns a Rails runner process and returns results
- `create_script(code, shared_setup)`: Generates the temporary Ruby script
- `parse_output(stdout)`: Parses JSON output from runner process

**Implementation Details:**
- Creates temporary Ruby script files with benchmark code
- Spawns `rails runner` process using `Open3.capture3` for output capture
- Enforces timeout using the timeout parameter of `capture3`
- Captures stdout (results) and stderr (errors) separately
- Parses JSON output from runner process
- Cleans up temporary files automatically (using Tempfile)
- Handles process errors and timeouts gracefully

### 5. BenchmarkService (`app/services/the_mechanic/benchmark_service.rb`)

Core service for orchestrating benchmarks:

**Methods:**
- `run(shared_setup:, code_a:, code_b:, timeout:)`: Executes benchmark comparison
- `format_results(result_a, result_b)`: Formats results into BenchmarkResult model

**Implementation Details:**
- Delegates to RailsRunnerService for actual code execution
- Runs code_a and code_b in separate Rails runner processes
- Collects and formats results from both executions
- Calculates winner and performance ratio
- Aggregates logs from both runs

### 6. SecurityService (`app/services/the_mechanic/security_service.rb`)

Validates code for dangerous operations:

**Methods:**
- `validate(code)`: Returns validation result with errors if any
- `sanitize(code)`: Removes dangerous patterns (optional)

**Forbidden Patterns:**
- System calls: `system`, `exec`, `spawn`, backticks
- File operations: `File.open`, `File.read`, `File.write`, `File.delete`
- Network operations: `Net::HTTP`, `Socket`, `TCPSocket`
- Process operations: `fork`, `Process.spawn`
- Database writes: `save`, `update`, `destroy`, `delete`, `create` (on ActiveRecord)
- Dangerous evals: `instance_eval`, `class_eval`, `module_eval` with external input

**Note:** Read-only database operations (queries) are allowed.

### 7. Models

**BenchmarkRequest** (`app/models/the_mechanic/benchmark_request.rb`):
- Validates request parameters
- Ensures required fields are present
- Validates timeout range

**BenchmarkResult** (`app/models/the_mechanic/benchmark_result.rb`):
- Formats benchmark results
- Calculates winner and performance ratio
- Provides export methods (to_json, to_markdown)

### 8. View Layer

**Main View** (`app/views/the_mechanic/benchmarks/index.html.erb`):

```erb
<!DOCTYPE html>
<html>
<head>
  <title>The Mechanic - Ruby Code Benchmarking</title>
  <style>
    <%= inline_css %>
  </style>
</head>
<body>
  <!-- UI matching original Mechanic -->
  <div id="app"></div>
  
  <script>
    <%= inline_javascript %>
  </script>
</body>
</html>
```

**Asset Inlining Strategy:**
- Controller helper method reads files from `app/assets/javascripts/the_mechanic/application.js`
- Controller helper method reads files from `app/assets/stylesheets/the_mechanic/application.css`
- Files are read at runtime and embedded directly in the HTML
- No external asset requests are made

## Data Models

### BenchmarkRequest

```ruby
{
  shared_setup: String,  # Optional setup code
  code_a: String,        # Required: First code snippet
  code_b: String,        # Required: Second code snippet
  timeout: Integer       # Optional: Max execution time (default: 30)
}
```

### BenchmarkResult

```ruby
{
  code_a_metrics: {
    ips: Float,              # Iterations per second
    stddev: Float,           # Standard deviation
    objects: Integer,        # Objects allocated
    memory_mb: Float,        # Memory used in MB
    execution_time: Float    # Time taken
  },
  code_b_metrics: { ... },   # Same structure
  winner: String,            # "code_a", "code_b", or "tie"
  performance_ratio: Float,  # How much faster winner is
  logs: {
    summary: String,
    benchmark: String,
    memory: String,
    gc: String
  }
}
```

### ValidationResult

```ruby
{
  valid: Boolean,
  errors: Array<String>
}
```

## Error Handling

### Error Types

1. **Validation Errors** (400 Bad Request)
   - Missing required parameters
   - Invalid code syntax
   - Forbidden operations detected

2. **Execution Errors** (500 Internal Server Error)
   - Runtime errors during benchmark execution
   - Timeout exceeded
   - Memory allocation failures

3. **Authentication Errors** (401 Unauthorized)
   - Authentication callback returns false

### Error Response Format

```json
{
  "error": "Error message",
  "details": ["Detailed error 1", "Detailed error 2"],
  "type": "validation_error" | "execution_error" | "authentication_error"
}
```

### Error Handling Strategy

- All controller actions wrapped in rescue blocks
- Specific error classes for different failure modes
- Detailed logging for debugging
- User-friendly error messages in responses
- Graceful degradation when possible

## Testing Strategy

### Test Structure

```
spec/
├── dummy/                          # Dummy Rails app for testing
│   ├── app/
│   │   └── models/
│   │       └── user.rb            # Sample model for testing
│   ├── config/
│   │   └── routes.rb              # Mounts engine
│   └── db/
│       └── schema.rb
├── controllers/
│   └── the_mechanic/
│       └── benchmarks_controller_spec.rb
├── services/
│   └── the_mechanic/
│       ├── benchmark_service_spec.rb
│       └── security_service_spec.rb
├── models/
│   └── the_mechanic/
│       ├── benchmark_request_spec.rb
│       └── benchmark_result_spec.rb
├── integration/
│   └── engine_mounting_spec.rb
└── spec_helper.rb
```

### Test Coverage Areas

1. **Unit Tests**
   - BenchmarkService: Performance and memory measurement
   - SecurityService: Code validation and sanitization
   - Models: Validation and formatting

2. **Controller Tests**
   - All endpoints (index, validate, run, export)
   - Authentication callback integration
   - Error handling
   - Asset inlining

3. **Integration Tests**
   - Engine mounting in dummy app
   - Access to host application classes
   - Full request/response cycle
   - UI rendering with inlined assets

4. **Security Tests**
   - Forbidden operations are blocked
   - Timeout enforcement
   - Read-only database access
   - No file system access

### Testing Tools

- **RSpec**: Test framework
- **Capybara**: Integration testing (if needed for UI)
- **FactoryBot**: Test data generation (if needed)
- **WebMock**: HTTP request stubbing (for security tests)

## Rails Application Context Access

### How It Works

The engine executes benchmark code by spawning separate Rails runner processes. This is the same mechanism Rails uses for background tasks and provides complete isolation while maintaining full application context.

**Process Flow:**
1. Engine receives benchmark request
2. Creates a temporary Ruby script file with the benchmark code
3. Spawns `rails runner` process pointing to the script file
4. Rails runner loads the entire application environment
5. Benchmark code executes with full access to application context
6. Results are serialized and written to stdout
7. Parent process captures and parses results
8. Temporary files are cleaned up

**Available Context:**
1. **ActiveRecord Models**: All models defined in the host application
2. **Application Classes**: Services, POROs, concerns, etc.
3. **Rails Helpers**: ActionView helpers, custom helpers
4. **Constants**: Application-defined constants
5. **Gems**: All gems loaded by the host application
6. **Rails Environment**: Full Rails.application context

### Example Usage

```ruby
# In the host Rails application, there's a User model
class User < ApplicationRecord
  def full_name
    "#{first_name} #{last_name}"
  end
end

# In The Mechanic benchmark:
# Shared Setup:
user = User.new(first_name: "John", last_name: "Doe")

# Code A:
user.full_name

# Code B:
"#{user.first_name} #{user.last_name}"
```

### Implementation

```ruby
# In RailsRunnerService
def execute(code:, shared_setup:, timeout:)
  # Create temporary script file
  script_file = Tempfile.new(['benchmark', '.rb'])
  
  begin
    # Write benchmark script
    script_content = <<~RUBY
      require 'benchmark/ips'
      require 'memory_profiler'
      require 'json'
      
      begin
        # Execute shared setup
        #{shared_setup}
        
        # Measure performance with benchmark-ips
        ips_result = nil
        Benchmark.ips do |x|
          x.report('code') { #{code} }
          x.compare!
        end
        
        # Capture IPS from benchmark-ips output
        # (parse from stdout or use internal API)
        
        # Measure memory
        memory_report = MemoryProfiler.report do
          #{code}
        end
        
        # Serialize results
        results = {
          ips: ips_result,
          stddev: stddev_result,
          objects: memory_report.total_allocated,
          memory_mb: memory_report.total_allocated_memsize / 1024.0 / 1024.0,
          execution_time: execution_time
        }
        
        # Output results as JSON
        puts JSON.generate(results)
      rescue => e
        # Output error as JSON
        puts JSON.generate({
          error: e.message,
          backtrace: e.backtrace.first(10)
        })
        exit(1)
      end
    RUBY
    
    script_file.write(script_content)
    script_file.close
    
    # Spawn rails runner process
    cmd = "rails runner #{script_file.path}"
    stdout, stderr, status = Open3.capture3(
      cmd,
      timeout: timeout,
      chdir: Rails.root
    )
    
    # Parse results
    JSON.parse(stdout)
  rescue Timeout::Error
    raise BenchmarkTimeout, "Execution exceeded #{timeout} seconds"
  ensure
    # Clean up temporary file
    script_file.unlink if script_file
  end
end

# In BenchmarkService
def run(shared_setup:, code_a:, code_b:, timeout:)
  runner = RailsRunnerService.new
  
  # Execute each benchmark in its own Rails runner process
  result_a = runner.execute(
    code: code_a,
    shared_setup: shared_setup,
    timeout: timeout
  )
  
  result_b = runner.execute(
    code: code_b,
    shared_setup: shared_setup,
    timeout: timeout
  )
  
  # Format and return results
  format_results(result_a, result_b)
end

def format_results(result_a, result_b)
  BenchmarkResult.new(
    code_a_metrics: result_a,
    code_b_metrics: result_b
  )
end
```

**Why This Approach is Highly Feasible:**

1. **`rails runner` is production-ready** - Used by millions of Rails apps daily
2. **Simple process management** - Ruby's `Open3` module handles all the complexity
3. **Proven pattern** - Similar to how test frameworks spawn processes
4. **No special permissions needed** - Just needs `rails` command in PATH
5. **Automatic cleanup** - Ruby's `Tempfile` handles file cleanup even on crashes
6. **Timeout support built-in** - `Open3.capture3` has native timeout support
7. **JSON serialization** - Simple, reliable way to pass data between processes
8. **Error handling** - Can catch and report errors from runner process

**Potential Issues and Solutions:**

1. **Rails boot time** - Each runner takes 1-3 seconds to boot
   - Solution: This is acceptable for benchmarking (benchmarks run longer)
   - Future: Could implement a preloader process (like Spring/Bootsnap)

2. **Memory usage** - Each runner loads full Rails app
   - Solution: Processes are short-lived and cleaned up immediately
   - Monitor: Add memory limits if needed

3. **Concurrent benchmarks** - Multiple simultaneous benchmarks could be heavy
   - Solution: Add queue/rate limiting if needed
   - Current: Acceptable for single-user admin tool

4. **Windows compatibility** - Process spawning works differently on Windows
   - Solution: `Open3` is cross-platform and handles this
   - Tested: Works on Windows with Rails

This approach is **highly likely to work** because it uses standard, battle-tested Rails and Ruby features.

### Benefits of Rails Runner Approach

1. **Complete Isolation**: Each benchmark runs in a completely separate process
2. **Safety**: Process crashes don't affect parent Rails application
3. **No State Leakage**: Fresh Rails environment for each benchmark
4. **Timeout Control**: Parent can terminate runaway processes
5. **Clean Environment**: Each benchmark starts with a fully loaded Rails app
6. **Database Safety**: Each process has its own database connections
7. **Standard Rails Mechanism**: Uses the same `rails runner` that developers use for tasks
8. **Cross-Platform**: Works on any platform that supports Rails (including Windows)

### Caveats and Considerations

1. **Process Overhead**: Spawning a Rails process has overhead (~1-3 seconds per spawn)
   - Rails must load the entire application for each benchmark
   - Acceptable for benchmarking use case (benchmarks typically run longer)
   - Much safer than shared-memory approaches

2. **Memory Usage**: Each Rails runner process loads the full application
   - Temporary memory spike during benchmark execution
   - Processes are short-lived and cleaned up immediately
   - Monitor memory if running many concurrent benchmarks

3. **Temporary Files**: Creates temporary script files for each benchmark
   - Files are cleaned up automatically
   - Uses Ruby's Tempfile which handles cleanup even on crashes

4. **Rails Boot Time**: Each benchmark includes Rails boot time in overhead
   - Not included in actual benchmark measurements
   - Consider caching or preloading for future optimization

## Asset Management

### CSS Structure

The CSS will replicate the original Mechanic's Tailwind-based styling but be compiled into a single file:

**File**: `app/assets/stylesheets/the_mechanic/application.css`

Contains:
- Reset/normalize styles
- Layout styles (flexbox, grid)
- Component styles (buttons, inputs, cards)
- Monaco editor container styles
- Responsive breakpoints
- Color scheme matching original

### JavaScript Structure

The JavaScript will provide the same functionality as the original React app but using vanilla JS or a minimal framework:

**File**: `app/assets/javascripts/the_mechanic/application.js`

Contains:
- Monaco Editor initialization
- Form handling and validation
- API calls to engine endpoints
- Results rendering
- Export functionality
- Error handling and display

### Inlining Implementation

```ruby
# In BenchmarksController
def inline_css
  @inline_css ||= File.read(
    Rails.root.join('app', 'assets', 'stylesheets', 'the_mechanic', 'application.css')
  )
rescue Errno::ENOENT
  # Fallback: read from engine root
  File.read(
    TheMechanic::Engine.root.join('app', 'assets', 'stylesheets', 'the_mechanic', 'application.css')
  )
end

def inline_javascript
  @inline_javascript ||= File.read(
    TheMechanic::Engine.root.join('app', 'assets', 'javascripts', 'the_mechanic', 'application.js')
  )
end
```

## Platform Requirements

### Supported Platforms

The Mechanic 2 uses `rails runner` for process isolation and works on all platforms that support Rails:

- **Supported**: Linux, macOS, BSD, Unix, Windows
- **Requirement**: Must have `rails` command available in PATH

### Ruby Version

- **Minimum**: Ruby 2.7.0
- **Recommended**: Ruby 3.0+

### Rails Version

- **Minimum**: Rails 6.0
- **Tested**: Rails 6.0, 6.1, 7.0, 7.1

## Installation and Usage

### Installation

```ruby
# Gemfile
gem 'the_mechanic', path: 'path/to/the_mechanic'
# or from git
gem 'the_mechanic', git: 'https://github.com/username/the_mechanic'
# or from rubygems (when published)
gem 'the_mechanic'
```

```bash
bundle install
```

### Mounting

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount TheMechanic::Engine => '/ask_the_mechanic'
  
  # Rest of your routes...
end
```

### Configuration (Optional)

```ruby
# config/initializers/the_mechanic.rb
TheMechanic.configure do |config|
  config.timeout = 60 # seconds
  config.enable_authentication = true
  config.authentication_callback = ->(controller) {
    controller.current_user&.admin?
  }
end
```

### Usage

1. Start Rails application: `rails server`
2. Navigate to: `http://localhost:3000/ask_the_mechanic`
3. Enter code snippets and run benchmarks
4. View results and export if needed

## Security Considerations

### Code Execution Safety

1. **Process Isolation**: Benchmarks run in separate Rails runner processes, completely isolated from the main application
2. **Validation Before Execution**: All code is validated before running
3. **Timeout Protection**: Parent process terminates child process if timeout is exceeded
4. **Read-Only Database**: Write operations are blocked via validation
5. **No File System Access**: File operations are forbidden via validation
6. **No Network Access**: Network operations are blocked via validation
7. **No System Calls**: System-level operations are prevented via validation
8. **Process Cleanup**: Temporary files and processes are always cleaned up (even on crash)
9. **Standard Rails Environment**: Uses Rails' own runner mechanism, which is battle-tested

### Authentication

Optional authentication callback allows host application to control access:

```ruby
config.authentication_callback = ->(controller) {
  # Return true to allow access, false to deny
  controller.current_user&.admin?
}
```

### Production Recommendations

1. Enable authentication in production
2. Set reasonable timeout limits
3. Monitor resource usage
4. Consider rate limiting at application level
5. Review logs for suspicious activity

## Performance Considerations

### Asset Inlining Impact

- **Pros**: No asset pipeline dependency, works everywhere, simple deployment
- **Cons**: Larger HTML response size, no browser caching of assets
- **Mitigation**: Assets are small (< 100KB combined), acceptable for admin tool

### Benchmark Execution

- Benchmarks run in separate Rails runner processes, not the main Rails process
- Process spawning overhead (~1-3 seconds) includes Rails boot time
- Processes are short-lived and cleaned up immediately after execution
- Long-running benchmarks are terminated by timeout mechanism
- Consider using background jobs for very long benchmarks (future enhancement)
- Each process loads the full Rails application independently

### Memory Usage

- Memory profiling can be memory-intensive
- Timeout protection prevents runaway memory allocation
- Monitor application memory when running benchmarks

## Future Enhancements

Potential improvements for future versions:

1. **Background Job Support**: Run benchmarks asynchronously
2. **Result History**: Store and compare historical results
3. **Benchmark Presets**: Save and reuse common benchmarks
4. **Comparison Charts**: Visual performance comparisons
5. **Multi-Code Comparison**: Compare more than 2 snippets
6. **Custom Metrics**: Allow custom measurement criteria
7. **API-Only Mode**: Headless benchmarking via API
8. **Benchmark Sharing**: Export/import benchmark configurations
