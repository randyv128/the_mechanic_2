# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TheMechanic2::BenchmarkRequest do
  describe '#initialize' do
    it 'accepts shared_setup parameter' do
      request = described_class.new(shared_setup: 'x = 10')
      expect(request.shared_setup).to eq('x = 10')
    end
    
    it 'accepts code_a parameter' do
      request = described_class.new(code_a: '1 + 1')
      expect(request.code_a).to eq('1 + 1')
    end
    
    it 'accepts code_b parameter' do
      request = described_class.new(code_b: '2 * 2')
      expect(request.code_b).to eq('2 * 2')
    end
    
    it 'accepts timeout parameter' do
      request = described_class.new(timeout: 60)
      expect(request.timeout).to eq(60)
    end
    
    it 'uses default timeout from configuration when not provided' do
      request = described_class.new
      expect(request.timeout).to eq(TheMechanic2.configuration.timeout)
    end
  end
  
  describe '#valid?' do
    context 'with valid parameters' do
      it 'returns true for valid request' do
        request = described_class.new(
          code_a: '1 + 1',
          code_b: '2 * 2',
          timeout: 30
        )
        expect(request.valid?).to be true
      end
      
      it 'returns true with shared_setup' do
        request = described_class.new(
          shared_setup: 'x = 10',
          code_a: 'x + 1',
          code_b: 'x * 2',
          timeout: 30
        )
        expect(request.valid?).to be true
      end
    end
    
    context 'with missing code_a' do
      it 'returns false when code_a is nil' do
        request = described_class.new(
          code_b: '2 * 2',
          timeout: 30
        )
        expect(request.valid?).to be false
      end
      
      it 'returns false when code_a is empty string' do
        request = described_class.new(
          code_a: '',
          code_b: '2 * 2',
          timeout: 30
        )
        expect(request.valid?).to be false
      end
      
      it 'returns false when code_a is whitespace only' do
        request = described_class.new(
          code_a: '   ',
          code_b: '2 * 2',
          timeout: 30
        )
        expect(request.valid?).to be false
      end
      
      it 'includes error message for missing code_a' do
        request = described_class.new(code_b: '2 * 2')
        request.valid?
        expect(request.errors).to include('Code A is required and cannot be empty')
      end
    end
    
    context 'with missing code_b' do
      it 'returns false when code_b is nil' do
        request = described_class.new(
          code_a: '1 + 1',
          timeout: 30
        )
        expect(request.valid?).to be false
      end
      
      it 'returns false when code_b is empty string' do
        request = described_class.new(
          code_a: '1 + 1',
          code_b: '',
          timeout: 30
        )
        expect(request.valid?).to be false
      end
      
      it 'includes error message for missing code_b' do
        request = described_class.new(code_a: '1 + 1')
        request.valid?
        expect(request.errors).to include('Code B is required and cannot be empty')
      end
    end
    
    context 'with invalid timeout' do
      it 'returns false when timeout is not a number' do
        request = described_class.new(
          code_a: '1 + 1',
          code_b: '2 * 2',
          timeout: 'invalid'
        )
        expect(request.valid?).to be false
      end
      
      it 'returns false when timeout is below minimum' do
        request = described_class.new(
          code_a: '1 + 1',
          code_b: '2 * 2',
          timeout: 0
        )
        expect(request.valid?).to be false
      end
      
      it 'returns false when timeout exceeds maximum' do
        request = described_class.new(
          code_a: '1 + 1',
          code_b: '2 * 2',
          timeout: 500
        )
        expect(request.valid?).to be false
      end
      
      it 'includes error message for non-numeric timeout' do
        request = described_class.new(
          code_a: '1 + 1',
          code_b: '2 * 2',
          timeout: 'invalid'
        )
        request.valid?
        expect(request.errors).to include('Timeout must be a number')
      end
      
      it 'includes error message for timeout below minimum' do
        request = described_class.new(
          code_a: '1 + 1',
          code_b: '2 * 2',
          timeout: 0
        )
        request.valid?
        expect(request.errors).to include('Timeout must be at least 1 second(s)')
      end
      
      it 'includes error message for timeout above maximum' do
        request = described_class.new(
          code_a: '1 + 1',
          code_b: '2 * 2',
          timeout: 500
        )
        request.valid?
        expect(request.errors).to include('Timeout cannot exceed 300 seconds')
      end
    end
    
    context 'with multiple validation errors' do
      it 'collects all errors' do
        request = described_class.new(timeout: 'invalid')
        request.valid?
        
        expect(request.errors.length).to be >= 3
        expect(request.errors).to include('Code A is required and cannot be empty')
        expect(request.errors).to include('Code B is required and cannot be empty')
        expect(request.errors).to include('Timeout must be a number')
      end
    end
  end
  
  describe '#error_messages' do
    it 'groups errors by field' do
      request = described_class.new(timeout: 'invalid')
      request.valid?
      
      errors = request.error_messages
      expect(errors).to have_key(:code_a)
      expect(errors).to have_key(:code_b)
      expect(errors).to have_key(:timeout)
      expect(errors).to have_key(:general)
    end
    
    it 'returns code_a errors' do
      request = described_class.new(code_b: '2 * 2', timeout: 30)
      request.valid?
      
      errors = request.error_messages
      expect(errors[:code_a]).not_to be_empty
    end
    
    it 'returns code_b errors' do
      request = described_class.new(code_a: '1 + 1', timeout: 30)
      request.valid?
      
      errors = request.error_messages
      expect(errors[:code_b]).not_to be_empty
    end
    
    it 'returns timeout errors' do
      request = described_class.new(code_a: '1 + 1', code_b: '2 * 2', timeout: 0)
      request.valid?
      
      errors = request.error_messages
      expect(errors[:timeout]).not_to be_empty
    end
  end
  
  describe '#all_errors' do
    it 'returns all errors as flat array' do
      request = described_class.new(timeout: 'invalid')
      request.valid?
      
      errors = request.all_errors
      expect(errors).to be_an(Array)
      expect(errors.length).to be >= 3
    end
  end
end
