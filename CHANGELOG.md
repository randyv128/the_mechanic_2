# Changelog

All notable changes to The Mechanic 2 will be documented in this file.

## [0.1.2] - 2025-10-16

### Fixed
- Fixed Rails 6+ autoloading compatibility using `eager_load_paths`
- Resolved "uninitialized constant TheMechanic2::BenchmarksController" error
- Proper path resolution using `Engine.root.join`

### Changed
- Switched from `autoload_paths` to `eager_load_paths` for Rails 6+ compatibility
- Simplified engine configuration for better Rails integration
- Updated README with correct mount path examples

## [0.1.1] - 2025-10-16

### Fixed
- Initial attempt to fix autoloading issue (superseded by 0.1.2)

### Changed
- Improved engine initialization for better Rails integration

## [0.1.0] - 2025-10-15

### Added - Initial Release

#### Core Features
- **Rails Engine Architecture**: Mountable engine with namespace isolation
- **Zero Configuration**: Just add gem and mount route - no setup required
- **Process Isolation**: Each benchmark runs in separate Rails runner process
- **Full Application Context**: Access to all models, services, and gems from host app
- **Security Validation**: Comprehensive code validation before execution
- **Performance Metrics**: IPS, standard deviation, object allocation, memory usage
- **Side-by-Side Comparison**: Compare two code snippets with winner determination
- **Export Functionality**: Download results as JSON or Markdown

#### Backend Services
- `BenchmarkService`: Orchestrates benchmark execution and result formatting
- `RailsRunnerService`: Spawns isolated Rails runner processes
- `SecurityService`: Validates code for dangerous operations
- `BenchmarkRequest`: Request parameter validation
- `BenchmarkResult`: Result formatting and export

#### Security Features
- Blocks system calls (`system`, `exec`, `spawn`, backticks)
- Blocks file operations (`File.open`, `File.read`, `File.write`)
- Blocks network operations (`Net::HTTP`, `Socket`, `URI.open`)
- Blocks database writes (`save`, `update`, `destroy`, `create`)
- Blocks thread creation (`Thread.new`)
- Blocks dangerous evals (`eval`, `instance_eval`, `class_eval`)
- Timeout protection (configurable, default 30 seconds)
- Process isolation for safety

#### Frontend
- Self-contained UI with inline CSS and JavaScript
- No external asset dependencies
- No asset pipeline required
- Responsive design (mobile, tablet, desktop)
- Real-time validation feedback
- Loading states and error handling
- Export buttons for JSON and Markdown

#### Configuration
- Optional timeout configuration (1-300 seconds)
- Optional authentication with callback support
- Sensible defaults work out of the box

#### API Endpoints
- `GET /` - Main benchmarking UI
- `POST /validate` - Validate code without executing
- `POST /run` - Execute benchmark comparison
- `POST /export` - Export results (JSON or Markdown)

#### Testing
- 167 comprehensive tests
- Unit tests for all services
- Model validation tests
- Security validation tests (44 tests)
- Integration tests
- 100% passing test suite

#### Documentation
- Comprehensive README with examples
- Installation instructions
- Configuration guide
- Security documentation
- Troubleshooting guide
- API endpoint documentation

#### Platform Support
- Ruby 2.7.0+
- Rails 6.0+
- Linux, macOS, BSD, Unix, Windows

### Technical Details

#### Dependencies
- `benchmark-ips` ~> 2.0 - Performance measurement
- `memory_profiler` ~> 1.0 - Memory tracking
- Rails >= 6.0

#### Architecture
- Namespace isolated engine (`TheMechanic2`)
- Service-oriented architecture
- Model-based request/response handling
- Controller-based HTTP API
- View-based UI rendering

#### Performance
- Rails runner process spawning (~1-3 seconds overhead)
- Isolated execution prevents state pollution
- Automatic cleanup of temporary files
- Configurable timeout protection

### Known Limitations

- Rails runner has boot time overhead (acceptable for benchmarking)
- Each benchmark spawns a new process (memory overhead)
- Windows support requires Rails runner compatibility
- No Monaco Editor integration yet (uses simple textareas)

### Future Enhancements

Potential improvements for future versions:
- Background job support for async benchmarking
- Result history and comparison
- Benchmark presets and templates
- Visual performance charts
- Multi-code comparison (>2 snippets)
- Monaco Editor integration
- Benchmark sharing/export
- API-only mode
- Custom metrics support

---

## Development

### Running Tests

```bash
bundle exec rspec
```

### Test Coverage

- 167 tests passing
- Services: 88 tests
- Models: 63 tests  
- Configuration: 12 tests
- Integration: 4 tests

### Contributing

See README.md for contribution guidelines.

---

**The Mechanic 2** - Built with ❤️ for the Ruby community
