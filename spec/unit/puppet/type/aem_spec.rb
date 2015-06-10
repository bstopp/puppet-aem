#!/usr/bin/env ruby

require 'spec_helper'
require 'puppet/type/aem'

describe Puppet::Type.type(:aem) do

  let(:source) { '/opt/aem/cq-author-4502.jar' }

  before :each, :platform => :linux do
    Puppet::Util::Platform.stubs(:windows?).returns(false)
  end

  before :each, :platform => :windows do
    Puppet::Util::Platform.stubs(:windows?).returns(true)
  end

  before :example do
    expect(File).to receive(:exists?).with(source).and_return(true)
    expect(Dir).to receive(:exists?).and_return(true)

    Puppet::Util.stubs(:absolute_path?).returns(true)
    @aem = Puppet::Type.type(:aem).new(
      {
        :name => 'author',
        :ensure => :present,
        :source => source,
        :version => '6.1'
    })
  end

  it 'should require a name' do
    expect {
      Puppet::Type.type(:aem).new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  describe 'name' do

    it 'should accept a name' do
      expect(@aem[:name]).to eq('author')
    end

    it 'name should be lowercase'  do
      @aem[:name] = 'PUBLISH'
      expect(@aem[:name]).to eq('publish')
    end

  end # End name

  describe 'source' do

    it 'should require source if ensure present' do
      expect(Dir).to receive(:exists?).and_return(true)
      expect {
        Puppet::Type.type(:aem).new({ :name => 'author', :ensure => :present })
      }.to raise_error(Puppet::Error, /Source jar is required/)
    end

    it 'should require source to exist' do
      expect(File).to receive(:exists?).with('/no/jar').and_return(false)
      expect {
        Puppet::Type.type(:aem).new({
          :name     => 'author',
          :ensure   => :present,
          :source   => '/no/jar',
        })
      }.to raise_error(Puppet::Error)
    end

  end # End source

  describe 'version' do

    #it 'should require version if ensure is present' do
    #  expect {
    #    File.stubs(:exists?).with(:file).returns(:true)
    #    Puppet::Type.type(:aem).new({:name => 'author', :ensure => :present, :source => :source})
    #  }.to raise_error(Puppet::Error, /Version is required/)
    #end

    it 'should accept a version' do
      expect(@aem[:version]).to eq('6.1')
    end

    it 'should accept a version major/minor/bug' do
      @aem[:version] = '5.6.1'
      expect(@aem[:version]).to eq('5.6.1')
    end

    it 'should require minor version' do
      expect{ @aem[:version] = '6' }.to raise_error(Puppet::Error)
    end

    it 'should not require bug version' do
      @aem[:version] = '6.1'
      expect(@aem[:version]).to eq('6.1')
    end

    it 'should allow no more than more than bug version' do
      expect{ @aem[:version] = '5.6.1.0' }.to raise_error(Puppet::Error)
    end
  end #End version

  describe 'home parameter' do

    context 'linux', :platform => :linux do

      it 'should have default linux value' do
        expect(@aem[:home]).to eq('/opt/aem')
      end

      it 'should accept linux absolute paths' do
        expect(Dir).to receive(:exists?).and_return(true)
        @aem[:home] = '/opt/aem/author'
        expect(@aem[:home]).to eq('/opt/aem/author')
      end

      it 'should require an absolute path' do
        Puppet::Util.stubs(:absolute_path?).returns(false)
        expect { @aem[:home] = 'not valid' }.to raise_error(Puppet::Error)
      end
    end # End linux

    context 'windows', :platform => :windows do

      it 'should have default windows value' do
        expect(@aem[:home]).to eq('C:/aem')
      end

      it 'should accept windows absolute paths' do
        expect(Dir).to receive(:exists?).and_return(true)
        @aem[:home] = 'C:/opt/aem/author'
        expect(@aem[:home]).to eq('C:/opt/aem/author')
      end
      
      it 'should require an absolute path' do
        Puppet::Util.stubs(:absolute_path?).returns(false)
        expect { @aem[:home] = 'not valid' }.to raise_error(Puppet::Error)
      end
    end # End windows

  end # End home

end