# frozen_string_literal: true

module TheMechanic2
  # Service for orchestrating benchmark execution
  # Coordinates between RailsRunnerService and result formatting
  class BenchmarkService
    # Executes a benchmark comparison between two code snippets
    # @param shared_setup [String] Optional setup code to run before both snippets
    # @param code_a [String] First code snippet to benchmark
    # @param code_b [String] Second code snippet to benchmark
    # @param timeout [Integer] Maximum execution time per benchmark in seconds
    # @return [Hash] Formatted benchmark results with winner and metrics
    def run(shared_setup:, code_a:, code_b:, timeout: 30)
      runner = RailsRunnerService.new
      
      # Execute code_a
      result_a = runner.execute(
        code: code_a,
        shared_setup: shared_setup,
        timeout: timeout
      )
      
      # Execute code_b
      result_b = runner.execute(
        code: code_b,
        shared_setup: shared_setup,
        timeout: timeout
      )
      
      # Format and return results
      format_results(result_a, result_b)
    end
    
    private
    
    # Formats the benchmark results and determines the winner
    # @param result_a [Hash] Results from code_a
    # @param result_b [Hash] Results from code_b
    # @return [Hash] Formatted results with winner and comparison
    def format_results(result_a, result_b)
      # Determine winner based on IPS (higher is better)
      winner = determine_winner(result_a[:ips], result_b[:ips])
      
      # Calculate performance ratio
      ratio = calculate_ratio(result_a[:ips], result_b[:ips], winner)
      
      {
        code_a_metrics: {
          ips: result_a[:ips],
          stddev: result_a[:stddev],
          objects: result_a[:objects],
          memory_mb: result_a[:memory_mb],
          execution_time: result_a[:execution_time]
        },
        code_b_metrics: {
          ips: result_b[:ips],
          stddev: result_b[:stddev],
          objects: result_b[:objects],
          memory_mb: result_b[:memory_mb],
          execution_time: result_b[:execution_time]
        },
        winner: winner,
        performance_ratio: ratio,
        summary: generate_summary(winner, ratio)
      }
    end
    
    # Determines which code snippet is the winner
    # @param ips_a [Float] Iterations per second for code A
    # @param ips_b [Float] Iterations per second for code B
    # @return [String] 'code_a', 'code_b', or 'tie'
    def determine_winner(ips_a, ips_b)
      # Consider it a tie if difference is less than 5%
      diff_percentage = ((ips_a - ips_b).abs / [ips_a, ips_b].max) * 100
      
      if diff_percentage < 5
        'tie'
      elsif ips_a > ips_b
        'code_a'
      else
        'code_b'
      end
    end
    
    # Calculates the performance ratio between the two code snippets
    # @param ips_a [Float] Iterations per second for code A
    # @param ips_b [Float] Iterations per second for code B
    # @param winner [String] The winner ('code_a', 'code_b', or 'tie')
    # @return [Float] Performance ratio (how much faster the winner is)
    def calculate_ratio(ips_a, ips_b, winner)
      return 1.0 if winner == 'tie'
      
      if winner == 'code_a'
        (ips_a / ips_b).round(2)
      else
        (ips_b / ips_a).round(2)
      end
    end
    
    # Generates a human-readable summary of the results
    # @param winner [String] The winner
    # @param ratio [Float] Performance ratio
    # @return [String] Summary text
    def generate_summary(winner, ratio)
      case winner
      when 'tie'
        'Both code snippets have similar performance (within 5% difference)'
      when 'code_a'
        "Code A is #{ratio}× faster than Code B"
      when 'code_b'
        "Code B is #{ratio}× faster than Code A"
      end
    end
  end
end
