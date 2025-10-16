# The Mechanic 2 🔧

A Rails Engine for benchmarking Ruby code with full access to your application's classes and dependencies.

## Features

- **Rails Engine Integration**: Mount directly into any Rails application
- **Full Application Context**: Benchmark code with access to all your models, services, and gems
- **Side-by-Side Comparison**: Compare two code snippets with detailed performance metrics
- **Security First**: Built-in code validation prevents dangerous operations
- **Zero Configuration**: Just add the gem and mount the route
- **Self-Contained**: All assets (CSS & JavaScript) are inlined - no asset pipeline required
- **Export Results**: Download results as JSON or Markdown

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'the_mechanic_2', path: 'path/to/the_mechanic_2'
# or from git
gem 'the_mechanic_2', git: 'https://github.com/yourusername/the_mechanic_2'
```

Then execute:

```bash
bundle install
```

## Usage

### 1. Mount the Engine

Add this to your `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  mount TheMechanic2::Engine => '/ask_the_mechanic_2'
  
  # Your other routes...
end
```

### 2. Start Your Rails Server

```bash
rails server
```

### 3. Access The Mechanic

Navigate to: `http://localhost:3000/ask_the_mechanic_2`

That's it! No additional setup required.

## Example Usage

### Basic Comparison

**Shared Setup:**
```ruby
arr = (1..1000).to_a
```

**Code A:**
```ruby
arr.sum
```

**Code B:**
```ruby
arr.reduce(:+)
```

### With ActiveRecord Models

**Shared Setup:**
```ruby
users = User.limit(100)
```

**Code A:**
```ruby
users.map(&:full_name)
```

**Code B:**
```ruby
users.pluck(:first_name, :last_name).map { |f, l| "#{f} #{l}" }
```

## Configuration (Optional)

Create an initializer at `config/initializers/the_mechanic_2.rb`:

```ruby
TheMechanic2.configure do |config|
  # Set custom timeout (default: 30 seconds)
  config.timeout = 60
  
  # Enable authentication (default: false)
  config.enable_authentication = true
  
  # Set authentication callback
  config.authentication_callback = ->(controller) {
    controller.current_user&.admin?
  }
end
```

### Configuration Options

- **timeout**: Maximum execution time per benchmark (1-300 seconds, default: 30)
- **enable_authentication**: Require authentication before allowing benchmarks (default: false)
- **authentication_callback**: Proc that receives the controller and returns true/false

## Security

The Mechanic includes comprehensive security validation:

- ✅ **Process Isolation**: Each benchmark runs in a separate Rails runner process
- ✅ **Code Validation**: Blocks dangerous operations before execution
- ✅ **Timeout Protection**: Automatically terminates long-running code
- ✅ **Read-Only Database**: Write operations are blocked
- ✅ **No File System Access**: File operations are forbidden
- ✅ **No Network Access**: Network operations are blocked
- ✅ **No System Calls**: System-level operations are prevented

### Forbidden Operations

The following operations are automatically blocked:

- System calls (`system`, `exec`, `spawn`, backticks)
- File operations (`File.open`, `File.read`, `File.write`)
- Network operations (`Net::HTTP`, `Socket`, `URI.open`)
- Database writes (`save`, `update`, `destroy`, `create`)
- Thread creation (`Thread.new`)
- Dangerous evals (`eval`, `instance_eval`, `class_eval`)

## API Endpoints

The engine provides the following endpoints:

- `GET /ask_the_mechanic_2` - Main UI
- `POST /ask_the_mechanic_2/validate` - Validate code without executing
- `POST /ask_the_mechanic_2/run` - Execute benchmark
- `POST /ask_the_mechanic_2/export` - Export results (JSON or Markdown)

## Platform Requirements

- **Ruby**: 2.7.0 or higher
- **Rails**: 6.0 or higher
- **Platform**: Linux, macOS, BSD, Unix, Windows

## Performance Metrics

The Mechanic measures:

- **IPS**: Iterations per second
- **Standard Deviation**: Performance consistency
- **Objects Allocated**: Memory allocation count
- **Memory Usage**: Total memory in MB
- **Execution Time**: Single run duration

## Development

### Running Tests

```bash
cd the_mechanic_2
bundle exec rspec
```

### Test Coverage

- 163 tests covering all services, models, and controllers
- Comprehensive security validation tests
- Integration tests with dummy Rails app

## How It Works

1. **Code Submission**: User submits two code snippets via the web interface
2. **Security Validation**: Code is validated for dangerous operations
3. **Process Spawning**: Each snippet runs in a separate `rails runner` process
4. **Measurement**: Performance and memory metrics are collected
5. **Comparison**: Results are compared and a winner is determined
6. **Display**: Results are shown side-by-side with detailed metrics

## Architecture

```
TheMechanic2::Engine
├── BenchmarksController    # HTTP endpoints
├── BenchmarkService        # Orchestrates benchmarking
├── RailsRunnerService      # Spawns isolated processes
├── SecurityService         # Validates code safety
├── BenchmarkRequest        # Request validation
└── BenchmarkResult         # Result formatting & export
```

## Troubleshooting

### Benchmarks are slow

- Reduce the timeout value
- Simplify your code snippets
- Check if your Rails app has slow boot time

### "Timeout exceeded" errors

- Increase the timeout in configuration
- Simplify your benchmark code
- Check for infinite loops

### Can't access my models

- Ensure your Rails app is fully loaded
- Check that models are properly defined
- Verify the engine is mounted correctly

### Authentication not working

- Verify `enable_authentication` is set to `true`
- Check your authentication callback logic
- Ensure the callback has access to the controller

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Credits

Inspired by the original [The Mechanic](https://github.com/yourusername/the_mechanic_2) standalone application.

Built with:
- [benchmark-ips](https://github.com/evanphx/benchmark-ips) - Performance measurement
- [memory_profiler](https://github.com/SamSaffron/memory_profiler) - Memory tracking

## Support

For issues and questions, please open an issue on GitHub.

---

**Made with ❤️ for the Ruby community**
