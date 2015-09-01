##!/usr/bin/env ruby
#
#require 'spec_helper'
#require 'puppet/type/aem_installer'
#require 'puppet/provider/aem_installer'
#
#describe Puppet::Provider::AemInstaller do
#
#  let(:resource) {
#    allow(File).to receive(:file?).with(any_args).at_least(1).and_call_original
#    allow(File).to receive(:directory?).with(any_args).at_least(1).and_call_original
#    Puppet::Type.type(:aem_installer).new({
#      :name     => 'foo',
#      :ensure   => :present,
#      :version  => '6.1',
#      :home     => '/opt/aem',
#    })
#  }
#
#  before do
#    @provider_class = Puppet::Type.type(:aem_installer).provide(:simple, :parent => Puppet::Provider::AemInstaller)
#    @provider_class.stubs(:suitable?).returns true
#    Puppet::Type.type(:aem_installer).stubs(:defaultprovider).returns @provider_class
#
#  end
#
#  before :each do
#    described_class.stubs(:which).with('find').returns('/bin/find')
#    described_class.stubs(:which).with('java').returns('/usr/bin/java')
#  end
#
#  describe 'self.prefetch' do
#    it 'should respond' do
#      expect(described_class).to respond_to(:prefetch)
#    end
#  end
#
#  describe 'exists?' do
#
#    shared_examples 'exists_check' do |opts|
#      it {
#        provider = @provider_class.new( { :ensure => opts[:ensure] })
#        expect( provider.exists? ).to eq(opts[:present])
#      }
#    end
#
#    describe 'ensure is absent' do
#      it_should_behave_like 'exists_check', :ensure => :absent, :present => false
#    end
#
#    describe 'ensure is present' do
#      it_should_behave_like 'exists_check', :ensure => :present, :present => true
#    end
#
#  end
#
#  describe 'destroy' do
#    it 'should remove quickstart folder' do
#      expect(FileUtils).to receive(:remove_entry_secure).with('/opt/aem/crx-quickstart/repository')
#      provider = @provider_class.new
#      provider.resource = resource
#      provider.destroy
#    end
#
#  end
#
#end