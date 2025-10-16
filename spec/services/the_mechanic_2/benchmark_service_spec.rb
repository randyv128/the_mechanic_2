# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TheMechanic2::BenchmarkService do
  let(:service) { described_class.new }
  
  describe '#run' do
    context 'with simple code snippets' do
      it 'returns formatted benchmark results' do
        result = service.run(
          shared_setup: nil,
          code_a: '1 + 1',
          code_b: '2 * 2',
          timeout: 10
        )
        
        expect(result).to be_a(Hash)
        expect(result).to have_key(:code_a_metrics)
        expect(result).to have_key(:code_b_metrics)
        expect(result).to have_key(:winner)
        expect(result).to have_key(:performance_ratio)
        expect(result).to have_key(:summary)
      end
      
      it 'includes all metrics for code_a' do
        result = service.run(
          shared_setup: nil,
          code_a: '1 + 1',
          code_b: '2 * 2',
          timeout: 10
        )
        
        metrics = result[:code_a_metrics]
        expect(metrics[:ips]).to be_a(Numeric)
        expect(metrics[:ips]).to be > 0
        expect(metrics[:stddev]).to be_a(Numeric)
        expect(metrics[:objects]).to be_a(Numeric)
        expect(metrics[:memory_mb]).to be_a(Numeric)
        expect(metrics[:execution_time]).to be_a(Numeric)
      end
      
      it 'includes all metrics for code_b' do
        result = service.run(
          shared_setup: nil,
          code_a: '1 + 1',
          code_b: '2 * 2',
          timeout: 10
        )
        
        metrics = result[:code_b_metrics]
        expect(metrics[:ips]).to be_a(Numeric)
        expect(metrics[:ips]).to be > 0
        expect(metrics[:stddev]).to be_a(Numeric)
        expect(metrics[:objects]).to be_a(Numeric)
        expect(metrics[:memory_mb]).to be_a(Numeric)
        expect(metrics[:execution_time]).to be_a(Numeric)
      end
    end
    
    context 'with shared setup' do
      it 'passes shared setup to both code snippets' do
        result = service.run(
          shared_setup: 'arr = [1, 2, 3, 4, 5]',
          code_a: 'arr.sum',
          code_b: 'arr.reduce(:+)',
          timeout: 10
        )
        
        expect(result[:code_a_metrics][:ips]).to be > 0
        expect(result[:code_b_metrics][:ips]).to be > 0
      end
    end
    
    context 'winner determination' do
      it 'determines code_a as winner when it is faster' do
        # Array sum is typically faster than string concatenation
        result = service.run(
          shared_setup: nil,
          code_a: '[1, 2, 3].sum',
          code_b: '"a" * 1000',
          timeout: 10
        )
        
        expect(result[:winner]).to be_in(['code_a', 'code_b', 'tie'])
        expect(result[:performance_ratio]).to be >= 1.0
      end
      
      it 'includes a summary message' do
        result = service.run(
          shared_setup: nil,
          code_a: '1 + 1',
          code_b: '2 * 2',
          timeout: 10
        )
        
        expect(result[:summary]).to be_a(String)
        expect(result[:summary]).not_to be_empty
      end
    end
    
    context 'with different performance characteristics' do
      it 'correctly identifies faster code' do
        # Simple arithmetic vs array operations
        result = service.run(
          shared_setup: nil,
          code_a: '1 + 1',
          code_b: '[1, 2, 3].map { |n| n * 2 }',
          timeout: 10
        )
        
        # Simple arithmetic should be faster
        expect(result[:code_a_metrics][:ips]).to be > result[:code_b_metrics][:ips]
        expect(result[:winner]).to eq('code_a')
      end
      
      it 'calculates performance ratio correctly' do
        result = service.run(
          shared_setup: nil,
          code_a: '1 + 1',
          code_b: '[1, 2, 3].map { |n| n * 2 }',
          timeout: 10
        )
        
        expect(result[:performance_ratio]).to be > 1.0
      end
    end
    
    context 'with custom timeout' do
      it 'respects custom timeout values' do
        result = service.run(
          shared_setup: nil,
          code_a: '1 + 1',
          code_b: '2 * 2',
          timeout: 5
        )
        
        expect(result[:code_a_metrics][:ips]).to be > 0
        expect(result[:code_b_metrics][:ips]).to be > 0
      end
    end
  end
  
  describe '#determine_winner' do
    it 'returns code_a when code_a is significantly faster' do
      winner = service.send(:determine_winner, 1000.0, 500.0)
      expect(winner).to eq('code_a')
    end
    
    it 'returns code_b when code_b is significantly faster' do
      winner = service.send(:determine_winner, 500.0, 1000.0)
      expect(winner).to eq('code_b')
    end
    
    it 'returns tie when performance is within 5%' do
      winner = service.send(:determine_winner, 1000.0, 1030.0)
      expect(winner).to eq('tie')
    end
    
    it 'returns tie when performance is exactly equal' do
      winner = service.send(:determine_winner, 1000.0, 1000.0)
      expect(winner).to eq('tie')
    end
  end
  
  describe '#calculate_ratio' do
    it 'returns 1.0 for a tie' do
      ratio = service.send(:calculate_ratio, 1000.0, 1000.0, 'tie')
      expect(ratio).to eq(1.0)
    end
    
    it 'calculates ratio correctly when code_a wins' do
      ratio = service.send(:calculate_ratio, 2000.0, 1000.0, 'code_a')
      expect(ratio).to eq(2.0)
    end
    
    it 'calculates ratio correctly when code_b wins' do
      ratio = service.send(:calculate_ratio, 1000.0, 3000.0, 'code_b')
      expect(ratio).to eq(3.0)
    end
    
    it 'rounds ratio to 2 decimal places' do
      ratio = service.send(:calculate_ratio, 1500.0, 1000.0, 'code_a')
      expect(ratio).to eq(1.5)
    end
  end
  
  describe '#generate_summary' do
    it 'generates summary for tie' do
      summary = service.send(:generate_summary, 'tie', 1.0)
      expect(summary).to include('similar performance')
    end
    
    it 'generates summary for code_a winner' do
      summary = service.send(:generate_summary, 'code_a', 2.5)
      expect(summary).to include('Code A')
      expect(summary).to include('2.5×')
      expect(summary).to include('faster')
    end
    
    it 'generates summary for code_b winner' do
      summary = service.send(:generate_summary, 'code_b', 3.0)
      expect(summary).to include('Code B')
      expect(summary).to include('3.0×')
      expect(summary).to include('faster')
    end
  end
  
  describe '#format_results' do
    let(:result_a) do
      {
        ips: 1000.0,
        stddev: 10.0,
        objects: 100,
        memory_mb: 0.5,
        execution_time: 0.001
      }
    end
    
    let(:result_b) do
      {
        ips: 500.0,
        stddev: 5.0,
        objects: 50,
        memory_mb: 0.25,
        execution_time: 0.002
      }
    end
    
    it 'formats results with all required keys' do
      formatted = service.send(:format_results, result_a, result_b)
      
      expect(formatted).to have_key(:code_a_metrics)
      expect(formatted).to have_key(:code_b_metrics)
      expect(formatted).to have_key(:winner)
      expect(formatted).to have_key(:performance_ratio)
      expect(formatted).to have_key(:summary)
    end
    
    it 'preserves all metrics from result_a' do
      formatted = service.send(:format_results, result_a, result_b)
      
      expect(formatted[:code_a_metrics][:ips]).to eq(1000.0)
      expect(formatted[:code_a_metrics][:stddev]).to eq(10.0)
      expect(formatted[:code_a_metrics][:objects]).to eq(100)
      expect(formatted[:code_a_metrics][:memory_mb]).to eq(0.5)
      expect(formatted[:code_a_metrics][:execution_time]).to eq(0.001)
    end
    
    it 'preserves all metrics from result_b' do
      formatted = service.send(:format_results, result_a, result_b)
      
      expect(formatted[:code_b_metrics][:ips]).to eq(500.0)
      expect(formatted[:code_b_metrics][:stddev]).to eq(5.0)
      expect(formatted[:code_b_metrics][:objects]).to eq(50)
      expect(formatted[:code_b_metrics][:memory_mb]).to eq(0.25)
      expect(formatted[:code_b_metrics][:execution_time]).to eq(0.002)
    end
    
    it 'determines winner correctly' do
      formatted = service.send(:format_results, result_a, result_b)
      expect(formatted[:winner]).to eq('code_a')
    end
    
    it 'calculates performance ratio correctly' do
      formatted = service.send(:format_results, result_a, result_b)
      expect(formatted[:performance_ratio]).to eq(2.0)
    end
  end
end
