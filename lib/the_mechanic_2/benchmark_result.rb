# frozen_string_literal: true

module TheMechanic2
  # Model for formatting and exporting benchmark results
  # Provides JSON and Markdown export capabilities
  class BenchmarkResult
    attr_reader :code_a_metrics, :code_b_metrics, :winner, :performance_ratio, :summary
    
    def initialize(data)
      @code_a_metrics = data[:code_a_metrics]
      @code_b_metrics = data[:code_b_metrics]
      @winner = data[:winner]
      @performance_ratio = data[:performance_ratio]
      @summary = data[:summary]
    end
    
    # Exports results as JSON
    # @return [String] JSON representation of results
    def to_json(*_args)
      {
        code_a_metrics: @code_a_metrics,
        code_b_metrics: @code_b_metrics,
        winner: @winner,
        performance_ratio: @performance_ratio,
        summary: @summary,
        timestamp: Time.now.iso8601
      }.to_json
    end
    
    # Exports results as Markdown
    # @return [String] Markdown formatted results
    def to_markdown
      <<~MARKDOWN
        # Ruby Benchmark Results
        
        **Winner:** #{winner_text}
        
        **Summary:** #{@summary}
        
        ## Performance Metrics
        
        | Metric | Code A | Code B |
        |--------|--------|--------|
        | IPS (iterations/sec) | #{format_number(@code_a_metrics[:ips])} | #{format_number(@code_b_metrics[:ips])} |
        | Standard Deviation | #{format_number(@code_a_metrics[:stddev])} | #{format_number(@code_b_metrics[:stddev])} |
        | Objects Allocated | #{format_number(@code_a_metrics[:objects])} | #{format_number(@code_b_metrics[:objects])} |
        | Memory (MB) | #{format_number(@code_a_metrics[:memory_mb])} | #{format_number(@code_b_metrics[:memory_mb])} |
        | Execution Time (sec) | #{format_number(@code_a_metrics[:execution_time])} | #{format_number(@code_b_metrics[:execution_time])} |
        
        ## Analysis
        
        #{analysis_text}
        
        ---
        
        *Generated at #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}*
      MARKDOWN
    end
    
    # Returns a hash representation of the results
    # @return [Hash] results as a hash
    def to_h
      {
        code_a_metrics: @code_a_metrics,
        code_b_metrics: @code_b_metrics,
        winner: @winner,
        performance_ratio: @performance_ratio,
        summary: @summary
      }
    end
    
    private
    
    def winner_text
      case @winner
      when 'code_a'
        "Code A (#{@performance_ratio}× faster)"
      when 'code_b'
        "Code B (#{@performance_ratio}× faster)"
      when 'tie'
        'Tie (similar performance)'
      else
        'Unknown'
      end
    end
    
    def analysis_text
      lines = []
      
      # Performance analysis
      if @winner == 'tie'
        lines << "Both code snippets have similar performance characteristics."
      else
        faster = @winner == 'code_a' ? 'Code A' : 'Code B'
        slower = @winner == 'code_a' ? 'Code B' : 'Code A'
        lines << "#{faster} is significantly faster than #{slower} by a factor of #{@performance_ratio}×."
      end
      
      # Memory analysis
      memory_diff = (@code_a_metrics[:memory_mb] - @code_b_metrics[:memory_mb]).abs
      if memory_diff > 0.01 # More than 0.01 MB difference
        less_memory = @code_a_metrics[:memory_mb] < @code_b_metrics[:memory_mb] ? 'Code A' : 'Code B'
        lines << "#{less_memory} uses less memory."
      else
        lines << "Both snippets have similar memory usage."
      end
      
      # Object allocation analysis
      obj_diff = (@code_a_metrics[:objects] - @code_b_metrics[:objects]).abs
      if obj_diff > 10 # More than 10 objects difference
        fewer_objects = @code_a_metrics[:objects] < @code_b_metrics[:objects] ? 'Code A' : 'Code B'
        lines << "#{fewer_objects} allocates fewer objects."
      end
      
      lines.join("\n\n")
    end
    
    def format_number(num)
      return '0' if num.nil?
      
      if num.is_a?(Float)
        if num < 0.01
          format('%.6f', num)
        elsif num < 1
          format('%.4f', num)
        elsif num < 100
          format('%.2f', num)
        else
          num.round.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
        end
      else
        num.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
      end
    end
  end
end
