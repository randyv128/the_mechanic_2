require 'benchmark/ips'
require 'memory_profiler'
require 'json'
require 'base64'
require 'stringio'

begin
  STDERR.puts "Starting benchmark..."
  # Decode the user code
  user_code = Base64.strict_decode64('YXJyLnN1bQ==')
  shared_setup_code = Base64.strict_decode64('YXJyID0gWzEsMiwzLDQsNV0=')
  STDERR.puts "Decoded code: #{user_code}"
  STDERR.puts "Decoded setup: #{shared_setup_code}"
  
  # Execute shared setup if provided
  STDERR.puts "Executing setup..."
  eval(shared_setup_code) if shared_setup_code
  STDERR.puts "Setup complete. arr = #{arr.inspect}"
  
  # Wrap code in a lambda that suppresses stdout
  STDERR.puts "Creating code block..."
  code_block = lambda do
    original_stdout = $stdout
    $stdout = File.open(File::NULL, 'w')
    begin
      eval(user_code)
    ensure
      $stdout.close unless $stdout == original_stdout
      $stdout = original_stdout
    end
  end
  
  # Capture Benchmark.ips results
  ips_result = nil
  stddev_result = nil
  
  # Redirect stdout temporarily to capture benchmark output
  original_stdout = $stdout
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
  $stdout = original_stdout
  
  puts "Benchmark output:"
  puts benchmark_output
  
rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace.first(10)
end
