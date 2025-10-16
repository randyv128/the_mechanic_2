# Requirements Document

## Introduction

The Mechanic 2 is a new Rails Engine gem that brings Ruby code benchmarking capabilities directly into any Rails application. Inspired by the original standalone Mechanic tool, this engine enables developers to benchmark Ruby code in a realistic environment with all the dependencies, models, and classes from their actual Rails application loaded. This addresses a key limitation of standalone benchmarking tools: testing code in isolation without access to the application's actual runtime environment.

## Requirements

### Requirement 1: Rails Engine Architecture

**User Story:** As a Rails developer, I want to mount The Mechanic as an engine in my Rails application, so that I can benchmark code with access to all my application's classes and dependencies.

#### Acceptance Criteria

1. WHEN the engine is added to a Rails application's Gemfile THEN it SHALL be installable as a standard Rails engine gem
2. WHEN the engine is mounted in routes.rb at '/ask_the_mechanic' THEN it SHALL provide all benchmarking functionality at that path
3. WHEN the engine is installed THEN it SHALL require no startup scripts, initialization commands, or additional setup beyond adding the gem and mounting the route
4. WHEN the engine is loaded THEN it SHALL have access to all classes, models, and dependencies from the host Rails application
5. IF the host application has ActiveRecord models THEN the engine SHALL be able to reference and use them in benchmark code
6. WHEN the engine is mounted THEN it SHALL not interfere with the host application's existing routes or functionality

### Requirement 2: Core Benchmarking Functionality

**User Story:** As a developer familiar with The Mechanic, I want the same powerful benchmarking features in the engine gem, so that I can perform comprehensive performance analysis.

#### Acceptance Criteria

1. WHEN I submit code snippets for benchmarking THEN the engine SHALL measure iterations per second (IPS) with statistical deviation
2. WHEN I submit code snippets for benchmarking THEN the engine SHALL track object allocation and memory usage
3. WHEN I provide shared setup code THEN it SHALL execute before both code snippets
4. WHEN benchmarks complete THEN the engine SHALL display side-by-side comparison results
5. WHEN I export results THEN the engine SHALL support JSON and Markdown formats
6. WHEN I submit code THEN the engine SHALL validate it for security before execution

### Requirement 3: Rails Application Context Access

**User Story:** As a Rails developer, I want to use my application's models and services in benchmark code, so that I can test real-world scenarios with actual data structures.

#### Acceptance Criteria

1. WHEN I reference an ActiveRecord model in benchmark code THEN it SHALL be accessible without requiring explicit imports
2. WHEN I use Rails helpers or utilities in benchmark code THEN they SHALL be available in the execution context
3. WHEN the host application has custom classes or modules THEN they SHALL be accessible in the benchmark execution environment
4. IF the benchmark code uses application constants THEN they SHALL resolve correctly
5. WHEN I access Rails.application in benchmark code THEN it SHALL reference the host application

### Requirement 4: Engine Configuration and Mounting

**User Story:** As a Rails developer, I want simple configuration options for the engine, so that I can customize its behavior for my application.

#### Acceptance Criteria

1. WHEN I mount the engine THEN it SHALL default to '/ask_the_mechanic' but allow custom mount paths
2. WHEN I configure the engine THEN it SHALL support setting execution timeout limits
3. WHEN I configure the engine THEN it SHALL support enabling/disabling specific security restrictions
4. IF I want to restrict access THEN the engine SHALL support authentication callbacks
5. WHEN the engine initializes THEN it SHALL provide sensible defaults that work without configuration

### Requirement 5: Self-Contained Inline Assets

**User Story:** As a Rails developer, I want the engine to work without external asset dependencies, so that it doesn't interfere with my application's asset pipeline or require additional configuration.

#### Acceptance Criteria

1. WHEN I access the engine's UI at '/ask_the_mechanic' THEN all CSS SHALL be inlined in the HTML response
2. WHEN I access the engine's UI THEN all JavaScript SHALL be inlined in the HTML response
3. WHEN the page loads THEN there SHALL be no external CSS or JavaScript fetch requests
4. WHEN the engine renders its view THEN it SHALL read CSS and JavaScript from the engine's asset directory and inline them
5. WHEN I view the UI THEN it SHALL have the exact same look and feel as the original Mechanic application
6. WHEN the engine is mounted THEN it SHALL not require integration with Sprockets, Webpacker, or any asset pipeline

### Requirement 6: Development and Testing Support

**User Story:** As a developer working on the engine, I want a dummy Rails application for testing, so that I can develop and test the engine in isolation.

#### Acceptance Criteria

1. WHEN I run the test suite THEN it SHALL use a dummy Rails application as the host
2. WHEN I start the development server THEN it SHALL mount the engine in the dummy application
3. WHEN I make changes to the engine THEN I SHALL be able to test them immediately in the dummy app
4. WHEN I run specs THEN they SHALL test the engine's functionality within a Rails context
5. WHEN I need to debug THEN the dummy application SHALL provide a realistic Rails environment

### Requirement 7: Security in Rails Context

**User Story:** As a Rails application owner, I want the engine to maintain security restrictions, so that benchmarked code cannot harm my application or data.

#### Acceptance Criteria

1. WHEN code is submitted for benchmarking THEN it SHALL be validated for dangerous operations
2. WHEN benchmark code executes THEN it SHALL not be able to modify database records (read-only access)
3. WHEN benchmark code executes THEN it SHALL not be able to access the file system
4. WHEN benchmark code executes THEN it SHALL not be able to make network requests
5. WHEN benchmark code executes THEN it SHALL have a configurable timeout to prevent infinite loops
6. IF benchmark code attempts forbidden operations THEN the engine SHALL reject it with a clear error message

### Requirement 8: Documentation and Examples

**User Story:** As a Rails developer new to The Mechanic, I want clear documentation and examples, so that I can quickly start benchmarking code in my application.

#### Acceptance Criteria

1. WHEN I install the engine THEN the README SHALL provide clear installation instructions showing only gem addition and route mounting
2. WHEN I want to mount the engine THEN the documentation SHALL show routing examples with the default '/ask_the_mechanic' path
3. WHEN I follow the installation steps THEN there SHALL be no mention of startup scripts, initialization commands, or additional setup
4. WHEN I want to benchmark Rails-specific code THEN the documentation SHALL provide example snippets
5. WHEN I want to configure the engine THEN the documentation SHALL list all available options
6. WHEN I encounter issues THEN the documentation SHALL include a troubleshooting section
