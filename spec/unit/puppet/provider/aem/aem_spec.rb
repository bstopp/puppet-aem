#!/usr/bin/evn ruby

require 'spec_helper'

provider_class = Puppet::Type.type(:aem).provider(:aem)

describe provider_class do


  let(:source) { '/opt/aem/cq-author-4502.jar' }
  let (:install_name) { 'cq-quickstart-*-standalone*.jar' }

  let(:installs) do
    <<-FIND_OUTPUT
    /opt/aem/crx-quickstart/app/cq-quickstart-5.6.1-standalone.jar
    /opt/aem/author/crx-quickstart/app/cq-quickstart-6.0.0-standalone.jar
    /opt/aem/publish/crx-quickstart/app/cq-quickstart-6.1.0-standalone-launchpad.jar
    FIND_OUTPUT
  end

  let(:aem_res) do
    Puppet::Type.type(:aem).new({
      :name     => 'aem',
      :ensure   => :present,
      :source   => source,
      :version  => '6.1',
      :home     => '/opt/aem',
      :provider => 'aem',
    })
  end

  let(:auth_res) do
    Puppet::Type.type(:aem).new({
      :name     => 'author',
      :ensure   => :present,
      :source   => source,
      :version  => '6.1',
      :home     => '/opt/aem/author',
      :provider => 'aem',
    })
  end

  let(:pub_res) do
    Puppet::Type.type(:aem).new({
      :name     => 'publish',
      :ensure   => :present,
      :source   => source,
      :version  => '6.1',
      :home     => '/opt/aem/publish',
      :provider => 'aem',
    })
  end
  
  let(:prov_resources) do
    providers = {}
    [aem_res, auth_res, pub_res].each do |res|
      provider = provider_class.new
      provider.resource = res
      providers[res[:name]] = provider
    end

    providers
  end
  
  let(:provider) do
    provider = provider_class.new
    provider.resource = aem_res
    provider
  end
  
  let(:execute_options) do
    {
      :failonfail             => true, 
      :combine                => true, 
      :custom_environment     => {},
    }
  end
  
  before :each do
    Puppet::Util.stubs(:which).with('find').returns('/bin/find')
    provider_class.stubs(:which).with('find').returns('/bin/find')
    Puppet::Util.stubs(:which).with('java').returns('/usr/bin/java')
  end


  describe 'self.instances' do

    it 'should have an instances method' do
      expect(described_class).to respond_to(:instances)
    end

    it 'returns an array of installs' do
      Puppet::Util::Execution.expects(:execpipe).with(['/bin/find', '/', "-name \"#{install_name}\"", '-type f']).yields(installs)

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
    # Why can't you test prefetch via unit tests?

    it 'should have a prefetch method' do
      expect(described_class).to respond_to(:prefetch)
    end

  end

  describe '#create' do
    
    let(:aem_res) do
      expect(File).to receive(:exists?).with(source).and_return(true)
      expect(Dir).to receive(:exists?).with('/opt/aem').and_return(true)
      Puppet::Type.type(:aem).new(
        :name     => 'myaem',
        :ensure   => :present,
        :home     => '/opt/aem',
        :source   => source
      )
    end

    it 'unpacks the jar to home directory' do
    
          
      expect(Puppet::Util::Execution).to receive(:execute).with(
        ['/usr/bin/java',['-jar', source, '-b', aem_res[:home], '-unpack']], execute_options
        ).and_return(0)
      
      provider.create
    end
  end
  
  describe '#destroy' do

    let(:aem_res) do
      expect(File).to receive(:exists?).with(source).and_return(true)
      expect(Dir).to receive(:exists?).with('/opt/aem').and_return(true)
      Puppet::Type.type(:aem).new(
        :name     => 'myaem',
        :ensure   => :present,
        :home     => '/opt/aem',
        :source   => source
      )
    end
    
    it 'deletes the home directory' do
      expect(Puppet::Util::Execution).to receive(:execute).with(
        ['/bin/find', ['/opt/aem', "-name \"#{install_name}\"", '-type f']], execute_options
        ).and_return("/opt/aem/crx-quickstart/app/cq-quickstart-5.6.1-standalone.jar\n")

      expect(FileUtils).to receive(:remove_entry_secure).with('/opt/aem/crx-quickstart')

      provider.destroy

    end
    
    it 'does nothing if catalog resource is not installed' do

      expect(Puppet::Util::Execution).to receive(:execute).with(
        ['/bin/find', ['/opt/aem', "-name \"#{install_name}\"", '-type f']], execute_options
        ).and_return('')

      expect(FileUtils).not_to receive(:remove_entry_secure)
      provider.destroy
    end
  end

end

