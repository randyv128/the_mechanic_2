# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TheMechanic2::Configuration do
  describe '#initialize' do
    it 'sets default timeout to 30 seconds' do
      config = described_class.new
      expect(config.timeout).to eq(30)
    end
    
    it 'sets enable_authentication to false by default' do
      config = described_class.new
      expect(config.enable_authentication).to be false
    end
    
    it 'sets authentication_callback to nil by default' do
      config = described_class.new
      expect(config.authentication_callback).to be_nil
    end
  end
  
  describe 'attribute accessors' do
    let(:config) { described_class.new }
    
    it 'allows setting and getting timeout' do
      config.timeout = 60
      expect(config.timeout).to eq(60)
    end
    
    it 'allows setting and getting enable_authentication' do
      config.enable_authentication = true
      expect(config.enable_authentication).to be true
    end
    
    it 'allows setting and getting authentication_callback' do
      callback = ->(controller) { controller.current_user&.admin? }
      config.authentication_callback = callback
      expect(config.authentication_callback).to eq(callback)
    end
  end
end

RSpec.describe TheMechanic2 do
  describe '.configuration' do
    it 'returns a Configuration instance' do
      expect(TheMechanic2.configuration).to be_a(TheMechanic2::Configuration)
    end
    
    it 'returns the same instance on multiple calls' do
      config1 = TheMechanic2.configuration
      config2 = TheMechanic2.configuration
      expect(config1).to be(config2)
    end
  end
  
  describe '.configure' do
    after do
      TheMechanic2.reset_configuration!
    end
    
    it 'yields the configuration instance' do
      expect { |b| TheMechanic2.configure(&b) }.to yield_with_args(TheMechanic2::Configuration)
    end
    
    it 'allows setting configuration options via block' do
      TheMechanic2.configure do |config|
        config.timeout = 120
        config.enable_authentication = true
      end
      
      expect(TheMechanic2.configuration.timeout).to eq(120)
      expect(TheMechanic2.configuration.enable_authentication).to be true
    end
    
    it 'persists configuration across multiple accesses' do
      TheMechanic2.configure do |config|
        config.timeout = 90
      end
      
      expect(TheMechanic2.configuration.timeout).to eq(90)
    end
  end
  
  describe '.reset_configuration!' do
    it 'resets configuration to defaults' do
      TheMechanic2.configure do |config|
        config.timeout = 120
        config.enable_authentication = true
      end
      
      TheMechanic2.reset_configuration!
      
      expect(TheMechanic2.configuration.timeout).to eq(30)
      expect(TheMechanic2.configuration.enable_authentication).to be false
    end
  end
end
