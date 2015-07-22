#!/usr/bin/env ruby

require 'spec_helper'
require 'puppet/type/aem'
require 'puppet/provider/aem'

describe Puppet::Provider::AEM do

  let(:source) { '/opt/aem/cq-author-4502.jar' }

  let(:resource) {
    allow(File).to receive(:file?).with(any_args).at_least(1).and_call_original
    expect(File).to receive(:file?).with(source).and_return(true)
    allow(File).to receive(:directory?).with(any_args).at_least(1).and_call_original
    expect(File).to receive(:directory?).with('/opt/aem').and_return(true)
    Puppet::Type.type(:aem).new({
      :name     => 'foo',
      :ensure   => :present,
      :source   => source,
      :version  => '6.1',
      :home     => '/opt/aem',
      :provider => :simple,
    })
  }

  before do
    @provider_class = Puppet::Type.type(:aem).provide(:simple, :parent => :linux) 
    @provider_class.stubs(:suitable?).returns true
    Puppet::Type.type(:aem).stubs(:defaultprovider).returns @provider_class

  end

  before :each do
    described_class.stubs(:which).with('find').returns('/bin/find')
    described_class.stubs(:which).with('java').returns('/usr/bin/java')
  end

  let(:mock_file) { double('File') }

  describe 'self.prefetch' do
    it 'should respond' do
      expect(described_class).to respond_to(:prefetch)
    end
  end

  describe 'exists?' do

    shared_examples 'exists_check' do |opts|
      it {
        provider = @provider_class.new( { :ensure => opts[:ensure] })
        expect( provider.exists? ).to eq(opts[:present])
      }
    end

    describe 'ensure is absent' do
      it_should_behave_like 'exists_check', :ensure => :absent, :present => false
    end

    describe 'ensure is present' do
      it_should_behave_like 'exists_check', :ensure => :present, :present => true
    end

  end

  describe 'destroy' do
    it 'should remove quickstart folder' do
      expect(File).to receive(:join).with('/opt/aem', 'crx-quickstart').and_call_original
      expect(FileUtils).to receive(:remove_entry_secure)
      provider = @provider_class.new
      provider.resource = resource
      provider.destroy
    end

  end

  describe 'attribute updates' do
    shared_examples 'update_env' do |opts|
      it {

        # Updates the env file
        expect(Puppet::Parser::Files).to receive(:find_template).and_return('templates/start-env.erb')
        envfile = File.join(resource[:home], 'crx-quickstart', 'bin', 'start-env')
        expect(File).to receive(:new).with(envfile, any_args).and_return(mock_file)
        expect(mock_file).to receive(:write) do |contents|

          if value = opts[:port] 
            match = /PORT=(#{value})/.match(contents).captures
            expect(match).not_to be(nil)
          end 

          if value = opts[:runmodes] 
            value = value.is_a?(Array) ? value.join(',') : value
            match = /RUNMODES=(#{value})/.match(contents).captures
            expect(match).not_to be(nil)
          end 
          
        end.and_return(0)
        
        expect(mock_file).to receive(:close)
        expect(File).to receive(:chmod).with(0750, any_args).and_return(0)
        expect(File).to receive(:chown).with(any_args)

        provider = @provider_class.new
        provider.resource = resource

        opts.each do |k, v|
          resource[k] = v
        end

        provider.flush

        expect(provider.properties).to eq(resource.to_hash)
        
        opts.each do |k, v|
          expect(provider.properties[k]).to eq(v)
        end
      }
    end

    describe 'update port' do
      it_should_behave_like 'update_env', :port => 8080
    end

    describe 'update runmodes' do
      it_should_behave_like 'update_env', :runmodes => ['dev', 'stage', 'client', 'vml']
    end

    describe 'update runmode' do
      it_should_behave_like 'update_env', :runmodes => ['production']
    end
  end

end