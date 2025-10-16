# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe TheMechanic2::BenchmarkResult do
  let(:sample_data) do
    {
      code_a_metrics: {
        ips: 1000.0,
        stddev: 10.0,
        objects: 100,
        memory_mb: 0.5,
        execution_time: 0.001
      },
      code_b_metrics: {
        ips: 500.0,
        stddev: 5.0,
        objects: 50,
        memory_mb: 0.25,
        execution_time: 0.002
      },
      winner: 'code_a',
      performance_ratio: 2.0,
      summary: 'Code A is 2.0× faster than Code B'
    }
  end
  
  let(:result) { described_class.new(sample_data) }
  
  describe '#initialize' do
    it 'stores code_a_metrics' do
      expect(result.code_a_metrics).to eq(sample_data[:code_a_metrics])
    end
    
    it 'stores code_b_metrics' do
      expect(result.code_b_metrics).to eq(sample_data[:code_b_metrics])
    end
    
    it 'stores winner' do
      expect(result.winner).to eq('code_a')
    end
    
    it 'stores performance_ratio' do
      expect(result.performance_ratio).to eq(2.0)
    end
    
    it 'stores summary' do
      expect(result.summary).to eq('Code A is 2.0× faster than Code B')
    end
  end
  
  describe '#to_json' do
    it 'returns valid JSON string' do
      json_string = result.to_json
      expect { JSON.parse(json_string) }.not_to raise_error
    end
    
    it 'includes code_a_metrics' do
      json_data = JSON.parse(result.to_json, symbolize_names: true)
      expect(json_data[:code_a_metrics]).to eq(sample_data[:code_a_metrics])
    end
    
    it 'includes code_b_metrics' do
      json_data = JSON.parse(result.to_json, symbolize_names: true)
      expect(json_data[:code_b_metrics]).to eq(sample_data[:code_b_metrics])
    end
    
    it 'includes winner' do
      json_data = JSON.parse(result.to_json, symbolize_names: true)
      expect(json_data[:winner]).to eq('code_a')
    end
    
    it 'includes performance_ratio' do
      json_data = JSON.parse(result.to_json, symbolize_names: true)
      expect(json_data[:performance_ratio]).to eq(2.0)
    end
    
    it 'includes summary' do
      json_data = JSON.parse(result.to_json, symbolize_names: true)
      expect(json_data[:summary]).to eq('Code A is 2.0× faster than Code B')
    end
    
    it 'includes timestamp' do
      json_data = JSON.parse(result.to_json, symbolize_names: true)
      expect(json_data[:timestamp]).to be_a(String)
      expect { Time.parse(json_data[:timestamp]) }.not_to raise_error
    end
  end
  
  describe '#to_markdown' do
    it 'returns a string' do
      expect(result.to_markdown).to be_a(String)
    end
    
    it 'includes title' do
      markdown = result.to_markdown
      expect(markdown).to include('# Ruby Benchmark Results')
    end
    
    it 'includes winner information' do
      markdown = result.to_markdown
      expect(markdown).to include('**Winner:**')
      expect(markdown).to include('Code A')
      expect(markdown).to include('2.0× faster')
    end
    
    it 'includes summary' do
      markdown = result.to_markdown
      expect(markdown).to include('**Summary:**')
      expect(markdown).to include(sample_data[:summary])
    end
    
    it 'includes performance metrics table' do
      markdown = result.to_markdown
      expect(markdown).to include('## Performance Metrics')
      expect(markdown).to include('| Metric | Code A | Code B |')
      expect(markdown).to include('IPS')
      expect(markdown).to include('Standard Deviation')
      expect(markdown).to include('Objects Allocated')
      expect(markdown).to include('Memory (MB)')
      expect(markdown).to include('Execution Time')
    end
    
    it 'includes analysis section' do
      markdown = result.to_markdown
      expect(markdown).to include('## Analysis')
    end
    
    it 'includes timestamp' do
      markdown = result.to_markdown
      expect(markdown).to include('Generated at')
    end
    
    context 'with tie result' do
      let(:tie_data) do
        sample_data.merge(
          winner: 'tie',
          performance_ratio: 1.0,
          summary: 'Both code snippets have similar performance'
        )
      end
      
      let(:tie_result) { described_class.new(tie_data) }
      
      it 'shows tie in winner text' do
        markdown = tie_result.to_markdown
        expect(markdown).to include('Tie')
      end
    end
    
    context 'with code_b winner' do
      let(:code_b_data) do
        sample_data.merge(
          winner: 'code_b',
          performance_ratio: 1.5,
          summary: 'Code B is 1.5× faster than Code A'
        )
      end
      
      let(:code_b_result) { described_class.new(code_b_data) }
      
      it 'shows code_b as winner' do
        markdown = code_b_result.to_markdown
        expect(markdown).to include('Code B')
        expect(markdown).to include('1.5× faster')
      end
    end
  end
  
  describe '#to_h' do
    it 'returns a hash' do
      expect(result.to_h).to be_a(Hash)
    end
    
    it 'includes all required keys' do
      hash = result.to_h
      expect(hash).to have_key(:code_a_metrics)
      expect(hash).to have_key(:code_b_metrics)
      expect(hash).to have_key(:winner)
      expect(hash).to have_key(:performance_ratio)
      expect(hash).to have_key(:summary)
    end
    
    it 'preserves all data' do
      hash = result.to_h
      expect(hash[:code_a_metrics]).to eq(sample_data[:code_a_metrics])
      expect(hash[:code_b_metrics]).to eq(sample_data[:code_b_metrics])
      expect(hash[:winner]).to eq(sample_data[:winner])
      expect(hash[:performance_ratio]).to eq(sample_data[:performance_ratio])
      expect(hash[:summary]).to eq(sample_data[:summary])
    end
  end
  
  describe '#format_number' do
    it 'formats small floats with 6 decimals' do
      formatted = result.send(:format_number, 0.000123)
      expect(formatted).to eq('0.000123')
    end
    
    it 'formats medium floats with 4 decimals' do
      formatted = result.send(:format_number, 0.1234)
      expect(formatted).to eq('0.1234')
    end
    
    it 'formats larger floats with 2 decimals' do
      formatted = result.send(:format_number, 12.345)
      expect(formatted).to eq('12.34')
    end
    
    it 'formats large numbers with commas' do
      formatted = result.send(:format_number, 1000000)
      expect(formatted).to eq('1,000,000')
    end
    
    it 'handles nil values' do
      formatted = result.send(:format_number, nil)
      expect(formatted).to eq('0')
    end
    
    it 'handles zero' do
      formatted = result.send(:format_number, 0)
      expect(formatted).to eq('0')
    end
  end
  
  describe 'winner_text' do
    it 'formats code_a winner correctly' do
      text = result.send(:winner_text)
      expect(text).to eq('Code A (2.0× faster)')
    end
    
    it 'formats code_b winner correctly' do
      code_b_result = described_class.new(sample_data.merge(winner: 'code_b', performance_ratio: 1.5))
      text = code_b_result.send(:winner_text)
      expect(text).to eq('Code B (1.5× faster)')
    end
    
    it 'formats tie correctly' do
      tie_result = described_class.new(sample_data.merge(winner: 'tie', performance_ratio: 1.0))
      text = tie_result.send(:winner_text)
      expect(text).to eq('Tie (similar performance)')
    end
  end
  
  describe 'analysis_text' do
    it 'includes performance analysis' do
      text = result.send(:analysis_text)
      expect(text).to include('faster')
    end
    
    it 'includes memory analysis when there is significant difference' do
      text = result.send(:analysis_text)
      expect(text).to include('memory')
    end
    
    it 'mentions object allocation when there is significant difference' do
      text = result.send(:analysis_text)
      expect(text).to include('objects')
    end
    
    context 'with tie result' do
      let(:tie_result) do
        described_class.new(sample_data.merge(winner: 'tie'))
      end
      
      it 'mentions similar performance' do
        text = tie_result.send(:analysis_text)
        expect(text).to include('similar performance')
      end
    end
  end
end
