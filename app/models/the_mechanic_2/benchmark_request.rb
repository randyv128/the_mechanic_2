# frozen_string_literal: true

module TheMechanic2
  # Model for validating benchmark request parameters
  # Ensures all required fields are present and valid
  class BenchmarkRequest
    attr_reader :shared_setup, :code_a, :code_b, :timeout, :errors
    
    # Minimum and maximum allowed timeout values
    MIN_TIMEOUT = 1
    MAX_TIMEOUT = 300
    
    def initialize(params = {})
      @shared_setup = params[:shared_setup]
      @code_a = params[:code_a]
      @code_b = params[:code_b]
      @timeout = params[:timeout] || TheMechanic2.configuration.timeout
      @errors = []
    end
    
    # Validates the request parameters
    # @return [Boolean] true if valid, false otherwise
    def valid?
      @errors = []
      
      validate_code_a
      validate_code_b
      validate_timeout
      
      @errors.empty?
    end
    
    # Returns validation errors as a hash
    # @return [Hash] errors grouped by field
    def error_messages
      {
        code_a: @errors.select { |e| e.include?('Code A') },
        code_b: @errors.select { |e| e.include?('Code B') },
        timeout: @errors.select { |e| e.include?('Timeout') },
        general: @errors.reject { |e| e.include?('Code A') || e.include?('Code B') || e.include?('Timeout') }
      }
    end
    
    # Returns all errors as a flat array
    # @return [Array<String>] all error messages
    def all_errors
      @errors
    end
    
    private
    
    def validate_code_a
      if @code_a.nil? || @code_a.strip.empty?
        @errors << 'Code A is required and cannot be empty'
      end
    end
    
    def validate_code_b
      if @code_b.nil? || @code_b.strip.empty?
        @errors << 'Code B is required and cannot be empty'
      end
    end
    
    def validate_timeout
      unless @timeout.is_a?(Numeric)
        @errors << 'Timeout must be a number'
        return
      end
      
      if @timeout < MIN_TIMEOUT
        @errors << "Timeout must be at least #{MIN_TIMEOUT} second(s)"
      end
      
      if @timeout > MAX_TIMEOUT
        @errors << "Timeout cannot exceed #{MAX_TIMEOUT} seconds"
      end
    end
  end
end
