# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'TheMechanic Benchmarks API' do
  describe 'POST /ask_the_mechanic_2/validate' do
    context 'with valid code' do
      it 'returns success for valid code snippets' do
        post '/ask_the_mechanic_2/validate', params: {
          code_a: '1 + 1',
          code_b: '2 * 2'
        }
        
        expect(last_response.status).to eq(200)
        json = JSON.parse(last_response.body)
        expect(json['valid']).to be true
      end
    end
    
    context 'with invalid code' do
      it 'returns errors for dangerous code' do
        post '/ask_the_mechanic_2/validate', params: {
          code_a: 'system("ls")',
          code_b: '2 * 2'
        }
        
        expect(last_response.status).to eq(422)
        json = JSON.parse(last_response.body)
        expect(json['valid']).to be false
      end
    end
  end
  
  describe 'POST /ask_the_mechanic_2/run' do
    it 'executes benchmark and returns results' do
      post '/ask_the_mechanic_2/run', params: {
        code_a: '1 + 1',
        code_b: '2 * 2',
        timeout: 10
      }
      
      expect(last_response.status).to eq(200)
      json = JSON.parse(last_response.body, symbolize_names: true)
      
      expect(json).to have_key(:code_a_metrics)
      expect(json).to have_key(:code_b_metrics)
      expect(json).to have_key(:winner)
    end
  end
end
