# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TheMechanic2::RailsRunnerService do
  let(:service) { described_class.new }
  
  describe '#execute' do
    context 'with simple arithmetic code' do
      it 'returns benchmark results' do
        code = '1 + 1'
        
        result = service.execute(code: code, timeout: 10)
        
        expect(result).to be_a(Hash)
        expect(result[:ips]).to be_a(Numeric)
        expect(result[:ips]).to be > 0
        expect(result[:stddev]).to be_a(Numeric)
        expect(result[:objects]).to be_a(Numeric)
        expect(result[:memory_mb]).to be_a(Numeric)
        expect(result[:execution_time]).to be_a(Numeric)
      end
    end
    
    context 'with string operations' do
      it 'benchmarks string concatenation' do
        code = '"hello" + " world"'
        
        result = service.execute(code: code, timeout: 10)
        
        expect(result[:ips]).to be > 0
        expect(result[:objects]).to be > 0
      end
    end
    
    context 'with array operations' do
      it 'benchmarks array mapping' do
        code = '[1, 2, 3].map { |n| n * 2 }'
        
        result = service.execute(code: code, timeout: 10)
        
        expect(result[:ips]).to be > 0
        expect(result[:memory_mb]).to be > 0
      end
    end
    
    context 'with shared setup' do
      it 'executes setup code before benchmark' do
        shared_setup = 'arr = [1, 2, 3, 4, 5]'
        code = 'arr.sum'
        
        result = service.execute(
          code: code,
          shared_setup: shared_setup,
          timeout: 10
        )
        
        expect(result[:ips]).to be > 0
      end
      
      it 'allows setup to define variables used in benchmark' do
        shared_setup = 'x = 10; y = 20'
        code = 'x + y'
        
        result = service.execute(
          code: code,
          shared_setup: shared_setup,
          timeout: 10
        )
        
        expect(result[:ips]).to be > 0
      end
    end
    
    context 'with invalid code' do
      it 'raises BenchmarkError for syntax errors' do
        code = 'this is not valid ruby'
        
        expect {
          service.execute(code: code, timeout: 10)
        }.to raise_error(TheMechanic2::RailsRunnerService::BenchmarkError)
      end
      
      it 'raises BenchmarkError for runtime errors' do
        code = '1 / 0'
        
        expect {
          service.execute(code: code, timeout: 10)
        }.to raise_error(TheMechanic2::RailsRunnerService::BenchmarkError)
      end
      
      it 'raises BenchmarkError for undefined variables' do
        code = 'undefined_variable + 1'
        
        expect {
          service.execute(code: code, timeout: 10)
        }.to raise_error(TheMechanic2::RailsRunnerService::BenchmarkError)
      end
    end
    
    context 'with timeout' do
      it 'raises BenchmarkTimeout for long-running code', :slow do
        code = 'sleep(100)'
        
        expect {
          service.execute(code: code, timeout: 1)
        }.to raise_error(TheMechanic2::RailsRunnerService::BenchmarkTimeout)
      end
      
      it 'respects custom timeout values', :slow do
        code = 'sleep(2)'
        
        expect {
          service.execute(code: code, timeout: 1)
        }.to raise_error(TheMechanic2::RailsRunnerService::BenchmarkTimeout)
      end
    end
  end
  
  describe '#create_script' do
    it 'creates a temporary file' do
      code = '1 + 1'
      script = service.send(:create_script, code, nil)
      
      expect(script).to be_a(Tempfile)
      expect(File.exist?(script.path)).to be true
      
      script.close
      script.unlink
    end
    
    it 'includes the benchmark code in the script' do
      code = 'puts "test"'
      script = service.send(:create_script, code, nil)
      
      content = File.read(script.path)
      expect(content).to include('puts "test"')
      
      script.close
      script.unlink
    end
    
    it 'includes shared setup when provided' do
      code = 'x + 1'
      shared_setup = 'x = 10'
      script = service.send(:create_script, code, shared_setup)
      
      content = File.read(script.path)
      expect(content).to include('x = 10')
      expect(content).to include('x + 1')
      
      script.close
      script.unlink
    end
    
    it 'includes benchmark-ips and memory_profiler requires' do
      code = '1 + 1'
      script = service.send(:create_script, code, nil)
      
      content = File.read(script.path)
      expect(content).to include("require 'benchmark/ips'")
      expect(content).to include("require 'memory_profiler'")
      expect(content).to include("require 'json'")
      
      script.close
      script.unlink
    end
  end
  
  describe '#generate_script_content' do
    it 'generates valid Ruby code' do
      code = '1 + 1'
      content = service.send(:generate_script_content, code, nil)
      
      expect(content).to be_a(String)
      expect(content).to include('require')
      expect(content).to include('JSON.generate')
    end
    
    it 'includes error handling' do
      code = '1 + 1'
      content = service.send(:generate_script_content, code, nil)
      
      expect(content).to include('rescue')
      expect(content).to include('error')
    end
  end
  
  describe '#parse_output' do
    it 'parses valid JSON output' do
      stdout = '{"ips":1000.0,"stddev":10.0,"objects":100,"memory_mb":0.5,"execution_time":0.001}'
      stderr = ''
      status = double('status', success?: true, exitstatus: 0)
      
      result = service.send(:parse_output, stdout, stderr, status)
      
      expect(result[:ips]).to eq(1000.0)
      expect(result[:stddev]).to eq(10.0)
      expect(result[:objects]).to eq(100)
      expect(result[:memory_mb]).to eq(0.5)
      expect(result[:execution_time]).to eq(0.001)
    end
    
    it 'raises BenchmarkError for invalid JSON' do
      stdout = 'not valid json'
      stderr = ''
      status = double('status', success?: true, exitstatus: 0)
      
      expect {
        service.send(:parse_output, stdout, stderr, status)
      }.to raise_error(TheMechanic2::RailsRunnerService::BenchmarkError, /Failed to parse/)
    end
    
    it 'raises BenchmarkError for failed process' do
      stdout = '{"error":"Something went wrong"}'
      stderr = 'Error details'
      status = double('status', success?: false, exitstatus: 1)
      
      expect {
        service.send(:parse_output, stdout, stderr, status)
      }.to raise_error(TheMechanic2::RailsRunnerService::BenchmarkError, /Benchmark failed/)
    end
  end
  
  describe 'temp file cleanup' do
    it 'cleans up temp files after successful execution' do
      code = '1 + 1'
      temp_files_before = Dir.glob('/tmp/benchmark*.rb').count
      
      service.execute(code: code, timeout: 10)
      
      temp_files_after = Dir.glob('/tmp/benchmark*.rb').count
      expect(temp_files_after).to eq(temp_files_before)
    end
    
    it 'cleans up temp files even after errors' do
      code = 'raise "error"'
      temp_files_before = Dir.glob('/tmp/benchmark*.rb').count
      
      begin
        service.execute(code: code, timeout: 10)
      rescue TheMechanic2::RailsRunnerService::BenchmarkError
        # Expected error
      end
      
      temp_files_after = Dir.glob('/tmp/benchmark*.rb').count
      expect(temp_files_after).to eq(temp_files_before)
    end
  end
end
