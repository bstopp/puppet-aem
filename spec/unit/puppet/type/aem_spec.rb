#!/usr/bin/evn rspec

require 'spec_helper'
require 'puppet/type/aem'

describe Puppet::Type.type(:aem) do

  before(:example, :windows => true) do
    stub_const('File::ALT_SEPARATOR', '\\')
  end

  it 'should require a name' do
    expect {
      Puppet::Type.type(:aem).new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  context 'name tests' do
    before :each do
      @aem = Puppet::Type.type(:aem).new(:name => 'author')
    end

    it 'should accept a name' do
      expect(@aem[:name]).to eq('author')
    end

    it 'name should be lowercase' do
      @aem[:name] = 'PUBLISH'
      expect(@aem[:name]).to eq('publish')
    end

  end # End name tests

  context 'version' do
  end

  context 'home parameter' do
    before :each do
      @aem = Puppet::Type.type(:aem).new(:name => 'author')
    end

    it 'should have default value' do
      expect(@aem[:home]).to eq('/opt/aem')
    end

    it 'should accept linux absolute paths' do
      @aem[:home] = '/opt/aem/author'
      expect(@aem[:home]).to eq('/opt/aem/author')
    end

    it 'should require an absolute path' do
      expect { @aem[:home] = 'not valid' }.to raise_error(Puppet::Error)
    end


    it 'should have default value', :windows => true do
      expect(@aem[:home]).to eq('C:/aem')
    end

    it 'should accept windows absolute paths', :windows => true do
      @aem[:home] = 'C:/opt/aem/author'
      expect(@aem[:home]).to eq('C:/opt/aem/author')
    end
  end # End home tests

end