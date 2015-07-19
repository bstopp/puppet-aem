#!/usr/bin/env ruby

require 'spec_helper'
require 'puppet/type/aem'
require 'puppet/provider/aem'

describe Puppet::Provider::AEM do

  let(:source) { '/opt/aem/cq-author-4502.jar' }

  let(:resource) {
    Puppet::Type.type(:aem).new({
      :name     => 'foo',
      :ensure   => :present,
      :source   => source,
      :version  => '6.1',
      :home     => '/opt/aem',
      :provider => 'simple',
    })
  }

  before do
    @provider_class = Puppet::Type.type(:aem).provide(:simple, :parent => Puppet::Provider::AEM) { mk_resource_methods }
    @provider_class.stubs(:suitable?).returns true
    Puppet::Type.type(:aem).stubs(:defaultprovider).returns @provider_class

  end

  before :example do
    expect(Puppet::Util).to receive(:absolute_path?).and_return(true).at_most(1)
    expect(File).to receive(:directory?).and_return(true).at_most(1)
    expect(File).to receive(:file?).with(source).and_return(true).at_most(1)
  end
  
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

end