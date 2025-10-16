# frozen_string_literal: true

module TheMechanic2
  # Main controller for benchmark operations
  # Handles UI rendering and API endpoints
  class BenchmarksController < ApplicationController
    before_action :check_authentication, if: -> { TheMechanic2.configuration.enable_authentication }
    
    # GET /ask_the_mechanic
    # Renders the main benchmarking UI
    def index
      render template: 'the_mechanic_2/benchmarks/index'
    end
    
    # POST /ask_the_mechanic_2/validate
    # Validates code without executing
    def validate
      code_a = params[:code_a]
      code_b = params[:code_b]
      
      errors = []
      
      # Validate code_a
      if code_a.present?
        validation_a = SecurityService.validate(code_a)
        errors.concat(validation_a[:errors].map { |e| "Code A: #{e}" }) unless validation_a[:valid]
      else
        errors << 'Code A: Code is required'
      end
      
      # Validate code_b
      if code_b.present?
        validation_b = SecurityService.validate(code_b)
        errors.concat(validation_b[:errors].map { |e| "Code B: #{e}" }) unless validation_b[:valid]
      else
        errors << 'Code B: Code is required'
      end
      
      # Validate shared_setup if provided
      if params[:shared_setup].present?
        validation_setup = SecurityService.validate(params[:shared_setup])
        errors.concat(validation_setup[:errors].map { |e| "Shared Setup: #{e}" }) unless validation_setup[:valid]
      end
      
      if errors.empty?
        render json: { valid: true, message: 'All code is valid' }
      else
        render json: { valid: false, errors: errors }, status: :unprocessable_entity
      end
    end
    
    # POST /ask_the_mechanic_2/run
    # Executes benchmark comparison
    def run
      # Validate request
      request = BenchmarkRequest.new(
        shared_setup: params[:shared_setup],
        code_a: params[:code_a],
        code_b: params[:code_b],
        timeout: params[:timeout]&.to_i
      )
      
      unless request.valid?
        render json: { error: 'Invalid request', errors: request.all_errors }, status: :unprocessable_entity
        return
      end
      
      # Validate code security
      validation_result = validate_code_security(request)
      unless validation_result[:valid]
        render json: { error: 'Security validation failed', errors: validation_result[:errors] }, status: :unprocessable_entity
        return
      end
      
      # Execute benchmark
      begin
        service = BenchmarkService.new
        results = service.run(
          shared_setup: request.shared_setup,
          code_a: request.code_a,
          code_b: request.code_b,
          timeout: request.timeout
        )
        
        render json: results
      rescue RailsRunnerService::BenchmarkTimeout => e
        render json: { error: 'Benchmark timeout', message: e.message }, status: :request_timeout
      rescue RailsRunnerService::BenchmarkError => e
        render json: { error: 'Benchmark execution failed', message: e.message }, status: :internal_server_error
      rescue StandardError => e
        render json: { error: 'Unexpected error', message: e.message }, status: :internal_server_error
      end
    end
    
    # POST /ask_the_mechanic_2/export
    # Exports results in specified format
    def export
      results_data = params[:results]
      format = params[:format] || 'json'
      
      unless results_data
        render json: { error: 'Results data is required' }, status: :unprocessable_entity
        return
      end
      
      begin
        result = BenchmarkResult.new(results_data.permit!.to_h.symbolize_keys)
        
        case format
        when 'json'
          render json: result.to_json, content_type: 'application/json'
        when 'markdown'
          render plain: result.to_markdown, content_type: 'text/markdown'
        else
          render json: { error: 'Invalid format. Use json or markdown' }, status: :unprocessable_entity
        end
      rescue StandardError => e
        render json: { error: 'Export failed', message: e.message }, status: :internal_server_error
      end
    end
    
    private
    
    # Checks authentication using configured callback
    def check_authentication
      callback = TheMechanic2.configuration.authentication_callback
      return unless callback
      
      unless callback.call(self)
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    end
    
    # Validates code security for all code snippets
    def validate_code_security(request)
      errors = []
      
      # Validate shared_setup if present
      if request.shared_setup.present?
        validation = SecurityService.validate(request.shared_setup)
        errors.concat(validation[:errors].map { |e| "Shared Setup: #{e}" }) unless validation[:valid]
      end
      
      # Validate code_a
      validation_a = SecurityService.validate(request.code_a)
      errors.concat(validation_a[:errors].map { |e| "Code A: #{e}" }) unless validation_a[:valid]
      
      # Validate code_b
      validation_b = SecurityService.validate(request.code_b)
      errors.concat(validation_b[:errors].map { |e| "Code B: #{e}" }) unless validation_b[:valid]
      
      { valid: errors.empty?, errors: errors }
    end
    
    # Helper methods for asset inlining (to be implemented later)
    helper_method :inline_css, :inline_javascript
    
    def inline_css
      @inline_css ||= read_asset_file('stylesheets/the_mechanic_2/application.css')
    end
    
    def inline_javascript
      @inline_javascript ||= read_asset_file('javascripts/the_mechanic_2/application.js')
    end
    
    def read_asset_file(path)
      file_path = TheMechanic2::Engine.root.join('app', 'assets', path)
      File.exist?(file_path) ? File.read(file_path) : ''
    rescue StandardError => e
      Rails.logger.error("Failed to read asset file #{path}: #{e.message}")
      ''
    end
  end
end
