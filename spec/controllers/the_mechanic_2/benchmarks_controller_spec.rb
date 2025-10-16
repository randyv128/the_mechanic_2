# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'TheMechanic2::BenchmarksController', type: :request do
  
  describe 'GET /ask_the_mechanic' do
    it 'returns http success' do
      get '/ask_the_mechanic'
      expect(response).to have_http_status(:success)
    end
  end
  
  describe 'POST /ask_the_mechanic_2/validate' do
    context 'with valid code' do
      it 'returns success for valid code snippets' do
        post '/ask_the_mechanic_2/validate', params: {
          code_a: '1 + 1',
          code_b: '2 * 2'
        }
        
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['valid']).to be true
      end
      
      it 'validates shared_setup when provided' do
        post '/ask_the_mechanic_2/validate', params: {
          shared_setup: 'x = 10',
          code_a: 'x + 1',
          code_b: 'x * 2'
        }
        
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['valid']).to be true
      end
    end
    
    context 'with invalid code' do
      it 'returns errors for dangerous code in code_a' do
        post "/ask_the_mechanic_2/validate", params: {
          code_a: 'system("ls")',
          code_b: '2 * 2'
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['valid']).to be false
        expect(json['errors']).to be_an(Array)
        expect(json['errors'].any? { |e| e.include?('Code A') }).to be true
      end
      
      it 'returns errors for dangerous code in code_b' do
        post "/ask_the_mechanic_2/validate", params: {
          code_a: '1 + 1',
          code_b: 'File.read("/etc/passwd")'
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['valid']).to be false
        expect(json['errors'].any? { |e| e.include?('Code B') }).to be true
      end
      
      it 'returns errors for missing code_a' do
        post "/ask_the_mechanic_2/validate", params: {
          code_b: '2 * 2'
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['valid']).to be false
        expect(json['errors'].any? { |e| e.include?('Code A') }).to be true
      end
      
      it 'returns errors for missing code_b' do
        post "/ask_the_mechanic_2/validate", params: {
          code_a: '1 + 1'
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['valid']).to be false
        expect(json['errors'].any? { |e| e.include?('Code B') }).to be true
      end
    end
  end
  
  describe "POST /ask_the_mechanic_2/run" do
    context 'with valid request' do
      it 'executes benchmark and returns results' do
        post "/ask_the_mechanic_2/run", params: {
          code_a: '1 + 1',
          code_b: '2 * 2',
          timeout: 10
        }
        
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body, symbolize_names: true)
        
        expect(json).to have_key(:code_a_metrics)
        expect(json).to have_key(:code_b_metrics)
        expect(json).to have_key(:winner)
        expect(json).to have_key(:performance_ratio)
        expect(json).to have_key(:summary)
      end
      
      it 'includes all metrics in results' do
        post "/ask_the_mechanic_2/run", params: {
          code_a: '1 + 1',
          code_b: '2 * 2',
          timeout: 10
        }
        
        json = JSON.parse(response.body, symbolize_names: true)
        
        expect(json[:code_a_metrics]).to have_key(:ips)
        expect(json[:code_a_metrics]).to have_key(:stddev)
        expect(json[:code_a_metrics]).to have_key(:objects)
        expect(json[:code_a_metrics]).to have_key(:memory_mb)
        expect(json[:code_a_metrics]).to have_key(:execution_time)
      end
      
      it 'handles shared_setup' do
        post "/ask_the_mechanic_2/run", params: {
          shared_setup: 'arr = [1, 2, 3]',
          code_a: 'arr.sum',
          code_b: 'arr.reduce(:+)',
          timeout: 10
        }
        
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body, symbolize_names: true)
        expect(json[:code_a_metrics][:ips]).to be > 0
      end
    end
    
    context 'with invalid request' do
      it 'returns error for missing code_a' do
        post "/ask_the_mechanic_2/run", params: {
          code_b: '2 * 2',
          timeout: 10
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Invalid request')
      end
      
      it 'returns error for missing code_b' do
        post "/ask_the_mechanic_2/run", params: {
          code_a: '1 + 1',
          timeout: 10
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Invalid request')
      end
      
      it 'returns error for invalid timeout' do
        post "/ask_the_mechanic_2/run", params: {
          code_a: '1 + 1',
          code_b: '2 * 2',
          timeout: 0
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Invalid request')
      end
    end
    
    context 'with security violations' do
      it 'returns error for dangerous code' do
        post "/ask_the_mechanic_2/run", params: {
          code_a: 'system("ls")',
          code_b: '2 * 2',
          timeout: 10
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Security validation failed')
      end
    end
  end
  
  describe "POST /ask_the_mechanic_2/export" do
    let(:sample_results) do
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
    
    context 'with JSON format' do
      it 'exports results as JSON' do
        post "/ask_the_mechanic_2/export", params: {
          results: sample_results,
          format: 'json'
        }
        
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/json')
      end
      
      it 'includes all result data in JSON' do
        post "/ask_the_mechanic_2/export", params: {
          results: sample_results,
          format: 'json'
        }
        
        json = JSON.parse(response.body, symbolize_names: true)
        expect(json).to have_key(:code_a_metrics)
        expect(json).to have_key(:code_b_metrics)
        expect(json).to have_key(:winner)
      end
    end
    
    context 'with Markdown format' do
      it 'exports results as Markdown' do
        post "/ask_the_mechanic_2/export", params: {
          results: sample_results,
          format: 'markdown'
        }
        
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('text/markdown')
      end
      
      it 'includes formatted content in Markdown' do
        post "/ask_the_mechanic_2/export", params: {
          results: sample_results,
          format: 'markdown'
        }
        
        expect(response.body).to include('# Ruby Benchmark Results')
        expect(response.body).to include('Code A')
        expect(response.body).to include('Performance Metrics')
      end
    end
    
    context 'with invalid format' do
      it 'returns error for unsupported format' do
        post "/ask_the_mechanic_2/export", params: {
          results: sample_results,
          format: 'xml'
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to include('Invalid format')
      end
    end
    
    context 'with missing results' do
      it 'returns error when results are missing' do
        post "/ask_the_mechanic_2/export", params: {
          format: 'json'
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to include('Results data is required')
      end
    end
  end
  
  describe 'authentication' do
    context 'when authentication is enabled' do
      before do
        TheMechanic2.configure do |config|
          config.enable_authentication = true
          config.authentication_callback = ->(controller) { controller.params[:authenticated] == 'true' }
        end
      end
      
      after do
        TheMechanic2.reset_configuration!
      end
      
      it 'allows access when authentication passes' do
        get "/ask_the_mechanic", params: { authenticated: 'true' }
        expect(response).to have_http_status(:success)
      end
      
      it 'denies access when authentication fails' do
        get "/ask_the_mechanic", params: { authenticated: 'false' }
        expect(response).to have_http_status(:unauthorized)
      end
      
      it 'returns unauthorized JSON response' do
        get "/ask_the_mechanic", params: { authenticated: 'false' }
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Unauthorized')
      end
    end
    
    context 'when authentication is disabled' do
      it 'allows access without authentication' do
        get "/ask_the_mechanic"
        expect(response).to have_http_status(:success)
      end
    end
  end
end
