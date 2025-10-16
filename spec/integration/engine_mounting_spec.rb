# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Engine Mounting' do
  it 'has the engine class defined' do
    expect(defined?(TheMechanic2::Engine)).to be_truthy
  end
  
  it 'engine inherits from Rails::Engine' do
    expect(TheMechanic2::Engine.superclass).to eq(Rails::Engine)
  end
  
  it 'has isolated namespace' do
    expect(TheMechanic2::Engine.isolated?).to be true
  end
  
  it 'has routes defined' do
    expect(TheMechanic2::Engine.routes).not_to be_nil
  end
end
