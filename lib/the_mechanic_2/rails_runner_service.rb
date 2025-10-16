# frozen_string_literal: true

require 'tempfile'
require 'json'
require 'open3'
require 'timeout'

module TheMechanic2
  # Service for spawning Rails runner processes to execute benchmark code
  # Each benchmark runs in a completely isolated Rails environment
  class RailsRunnerService
    class BenchmarkTimeout < StandardError; end
    class BenchmarkError < StandardError; end
    
    # Executes benchmark code in a separate Rails runner process
    # @param code [String] The Ruby code to benchmark
    # @param shared_setup [String] Optional setup code to run before benchmark
    # @param timeout [Integer] Maximum execution time in seconds
    # @return [Hash] Benchmark results with IPS, memory, and other metrics
    def execute(code:, shared_setup: nil, timeout: 30)
      script_file = create_script(code, shared_setup)
      
      begin
        stdout, stderr, status = spawn_runner(script_file.path, timeout)
        parse_output(stdout, stderr, status)
      ensure
        script_file.close
        script_file.unlink
      end
    end
    
    private
    
    # Creates a temporary Ruby script file with the benchmark code
    # @param code [String] The benchmark code
    # @param shared_setup [String] Optional setup code
    # @return [Tempfile] The temporary script file
    def create_script(code, shared_setup)
      script_file = Tempfile.new(['benchmark', '.rb'])
      
      script_content = generate_script_content(code, shared_setup)
      script_file.write(script_content)
      script_file.flush
      script_file.rewind
      
      script_file
    end
    
    # Generates the complete script content for benchmarking
    # @param code [String] The benchmark code
    # @param shared_setup [String] Optional setup code
    # @return [String] The complete Ruby script
    def generate_script_content(code, shared_setup)
      require 'base64'
      
      # Encode the code and setup to avoid interpolation issues
      encoded_code = Base64.strict_encode64(code)
      encoded_setup = shared_setup ? Base64.strict_encode64(shared_setup) : nil
      
      # Generate script with Base64 encoded code
      <<~RUBY
        require 'benchmark/ips'
        require 'memory_profiler'
        require 'json'
        require 'base64'
        require 'stringio'
        
        begin
          # Decode the user code
          user_code = Base64.strict_decode64('#{encoded_code}')
          #{encoded_setup ? "shared_setup_code = Base64.strict_decode64('#{encoded_setup}')" : "shared_setup_code = nil"}
          
          # Create a shared binding for eval context
          shared_binding = binding
          
          # Execute shared setup if provided
          eval(shared_setup_code, shared_binding) if shared_setup_code
          
          # Wrap code in a lambda that suppresses stdout
          code_block = lambda do
            original_stdout = $stdout
            $stdout = File.open(File::NULL, 'w')
            begin
              eval(user_code, shared_binding)
            ensure
              $stdout.close unless $stdout == original_stdout
              $stdout = original_stdout
            end
          end
          
          # Capture Benchmark.ips results
          ips_result = nil
          stddev_result = nil
          
          # Save the real stdout
          real_stdout = $stdout
          
          # Redirect stdout temporarily to capture benchmark output
          $stdout = StringIO.new
          
          Benchmark.ips do |x|
            x.config(time: 5, warmup: 2)
            
            x.report('benchmark') do
              code_block.call
            end
            
            # Store the results
            x.compare!
          end
          
          # Get the benchmark output
          benchmark_output = $stdout.string
          $stdout = real_stdout
          
          # Parse IPS from benchmark output
          # Format: "benchmark     42.072M (± 2.1%) i/s"
          # Can be in format like "42.072M" or "123.456k" or just "1234.5"
          if benchmark_output =~ /benchmark\\s+([\\d.]+)([MKk]?)\\s+\\(±\\s*([\\d.]+)%\\)\\s+i\\/s/
            value = $1.to_f
            unit = $2
            stddev_percent = $3.to_f
            
            # Convert to actual IPS based on unit
            case unit
            when 'M'
              ips_result = value * 1_000_000
            when 'K', 'k'
              ips_result = value * 1_000
            else
              ips_result = value
            end
            
            stddev_result = ips_result * (stddev_percent / 100.0)
          else
            # Fallback if parsing fails
            ips_result = 0.0
            stddev_result = 0.0
          end
          
          # Measure memory usage (suppress output)
          null_file = File.open(File::NULL, 'w')
          $stdout = null_file
          memory_report = MemoryProfiler.report do
            100.times do
              code_block.call
            end
          end
          null_file.close
          $stdout = real_stdout
          
          # Calculate execution time for a single run
          execution_start = Time.now
          code_block.call
          execution_time = Time.now - execution_start
          
          # Serialize results as JSON
          results = {
            ips: ips_result.round(2),
            stddev: stddev_result.round(2),
            objects: memory_report.total_allocated,
            memory_mb: (memory_report.total_allocated_memsize / 1024.0 / 1024.0).round(4),
            execution_time: execution_time.round(6)
          }
          
          puts JSON.generate(results)
          
        rescue => e
          # Output error as JSON
          error_result = {
            error: e.message,
            backtrace: e.backtrace.first(10)
          }
          puts JSON.generate(error_result)
          exit(1)
        end
      RUBY
    end
    
    # Spawns a Rails runner process with the script
    # @param script_path [String] Path to the temporary script file
    # @param timeout [Integer] Maximum execution time
    # @return [Array] stdout, stderr, and status
    def spawn_runner(script_path, timeout)
      # For testing, use ruby directly. In production, this will be called from a real Rails app
      # where rails runner will work properly
      cmd = if ENV['RAILS_ENV'] == 'test'
              "bundle exec ruby #{script_path}"
            else
              "bundle exec rails runner #{script_path}"
            end
      
      Timeout.timeout(timeout) do
        Open3.capture3(
          cmd,
          chdir: Rails.root.to_s
        )
      end
    rescue Timeout::Error
      raise BenchmarkTimeout, "Execution exceeded #{timeout} seconds"
    end
    
    # Parses the output from the Rails runner process
    # @param stdout [String] Standard output from the process
    # @param stderr [String] Standard error from the process
    # @param status [Process::Status] Process exit status
    # @return [Hash] Parsed benchmark results
    def parse_output(stdout, stderr, status)
      if status.success?
        begin
          # Extract the JSON line from stdout (last line should be JSON)
          json_line = stdout.lines.last&.strip
          raise BenchmarkError, "No JSON output found" if json_line.nil? || json_line.empty?
          
          JSON.parse(json_line, symbolize_names: true)
        rescue JSON::ParserError => e
          raise BenchmarkError, "Failed to parse benchmark results: #{e.message}\nOutput: #{stdout}"
        end
      else
        # Try to parse error from stdout
        begin
          json_line = stdout.lines.last&.strip
          if json_line && !json_line.empty?
            error_data = JSON.parse(json_line, symbolize_names: true)
            raise BenchmarkError, "Benchmark failed: #{error_data[:error]}"
          else
            raise BenchmarkError, "Benchmark failed with exit code #{status.exitstatus}\nStderr: #{stderr}\nStdout: #{stdout}"
          end
        rescue JSON::ParserError
          raise BenchmarkError, "Benchmark failed with exit code #{status.exitstatus}\nStderr: #{stderr}\nStdout: #{stdout}"
        end
      end
    end
  end
end
