#!/usr/bin/evn ruby

#require 'puppet'
require 'spec_helper'
#require 'puppet_spec/compiler'
#require 'puppet/parser/functions'

provider_class = Puppet::Type.type(:aem).provider(:aem)

describe Puppet::Type.type(:aem).provider(:aem) do

  let (:install_name) { 'cq-quickstart-*-standalone*.jar' }

  let (:installs) do
    <<-FIND_OUTPUT
/opt/aem/crx-quickstart/app/cq-quickstart-5.6.1-standalone.jar
/opt/aem/author/crx-quickstart/app/cq-quickstart-6.0.0-standalone.jar
/opt/aem/publish/crx-quickstart/app/cq-quickstart-6.1.0-standalone-launchpad.jar
FIND_OUTPUT
  end

  before :each do
    Puppet::Util.stubs(:which).with('find').returns('/bin/find')
    provider_class.stubs(:which).with('find').returns('/bin/find')
  end

  describe 'self.instances' do

    it 'should have an instances method' do
      expect(described_class).to respond_to :instances
    end

    it 'returns an array of installs' do
      Puppet::Util::Execution.expects(:execpipe).with("/bin/find / -name #{install_name} -type f").yields(installs)

      installed = provider_class.instances

      expect(installed[0].properties).to eq(
        {
          :name     => '/opt/aem',
          :home     => '/opt/aem',
          :version  => '5.6.1',
          :ensure   => :present,
        }
      )
      expect(installed[1].properties).to eq(
        {
          :name     => '/opt/aem/author',
          :home     => '/opt/aem/author',
          :version  => '6.0.0',
          :ensure   => :present,
        }
      )
      expect(installed.last.properties).to eq(
        {
          :name     => '/opt/aem/publish',
          :home     => '/opt/aem/publish',
          :version  => '6.1.0',
          :ensure   => :present,
        }
      )

    end

  end

  describe 'self.prefetch' do

    before :each do
      #Puppet::Parser::Functions.function(:create_resources)
    end

    it 'should have a prefetch  method' do
      expect(described_class).to respond_to :prefetch
    end
    
    it 'should populate resources with provider' do
      Puppet::Util::Execution.expects(:execpipe).with("/bin/find / -name #{install_name} -type f").yields(installs)

      #let(:command) do
      #  <<-END_CATALOG
#create_resoruces(aem, {'author'=> {:home=> '/opt/aem/author',:version  => '6.0.0',:ensure=> :present}}
#END_CATALOG
      #end

      aem = { 'author' => {:home=> '/opt/aem/author',:version  => '6.0.0',:ensure=> :present}}
      #catalog = compile_to_catalogcreate_resources(:aem, :command)
      res = Puppet::Parser::Function.create_resources(aem, aem)
      expect(catalog.resource(:ame, 'author')[:ensure]).to eq(:present)
    end
  end
  
end

