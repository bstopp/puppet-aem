#!/usr/bin/evn ruby

require 'spec_helper'

describe Puppet::Type.type(:aem_installer).provider(:default) do

  let(:resource) {
    allow(File).to receive(:file?).with(any_args).at_least(1).and_call_original
    allow(File).to receive(:directory?).with(any_args).at_least(1).and_call_original
    Puppet::Type.type(:aem_installer).new({
      :name     => 'foo',
      :ensure   => :present,
      :version  => '6.1',
      :home     => '/opt/aem',
    })
  }

  let(:install_name) { 'cq-quickstart-*-standalone*.jar' }

  let(:installs) { '/opt/aem/crx-quickstart/app/cq-quickstart-6.0.0-standalone.jar' }

  let(:resource) do
    Puppet::Type.type(:aem_installer).new({
      :name     => 'aem',
      :ensure   => :present,
      :version  => '6.1',
      :home     => '/opt/aem',
      :provider => 'default',
      :snooze   => 0,
    })
  end

  let(:provider) do
    provider = described_class.new
    provider.resource = resource
    provider
  end

  let(:execute_options) do
    {
      :failonfail             => true,
      :combine                => true,
      :custom_environment     => {},
    }
  end

  let(:mock_response) do
    class MockResponse
    end
    MockResponse.new
  end

  let(:exception) do
    Errno::ECONNREFUSED.new
  end

  let(:mock_file) { double('File') }

  Stat = Struct.new(:uid, :gid)
  Id = Struct.new(:name)

  ugid = 2001
  filestats = Stat.new(ugid, ugid)
  id = Id.new('aem')

  before do
    @provider_class = described_class
    @provider_class.stubs(:suitable?).returns true
    Puppet::Type.type(:aem_installer).stubs(:defaultprovider).returns @provider_class

  end

  before :each do
    described_class.stubs(:which).with('find').returns('/bin/find')
    described_class.stubs(:which).with('java').returns('/usr/bin/java')
  end

  describe 'aem_installer class' do
    describe 'self.prefetch' do
      it 'should respond' do
        expect(described_class).to respond_to(:prefetch)
      end
    end

    describe 'self.instances' do

      it 'should have an instances method' do
        expect(described_class).to respond_to(:instances)
      end

      shared_examples 'self.instances' do |opts|
        it {
          expect(Puppet::Util::Execution).to receive(:execpipe).with(['/bin/find', '/', "-name \"#{install_name}\"", '-type f']).and_yield(installs)
          expect(File).to receive(:stat).and_return(filestats)
          expect(Etc).to receive(:getpwuid).with(ugid).and_return(id)
          expect(Etc).to receive(:getgrgid).with(ugid).and_return(id)
          expect(File).to receive(:exist?).and_return(true)

          props = {
            :name             => opts[:home],
            :home             => opts[:home],
            :ensure           => :present,
            :user             => 'aem',
            :group            => 'aem',
          }

          props[:version] = opts[:version] if opts[:version]

          installed = described_class.instances

          expect(installed[0].properties).to eq(props)
        }
      end

      describe 'should support standard filename' do

        let(:installs) { '/opt/aem/crx-quickstart/app/cq-quickstart-5.6.1-standalone.jar' }

        it_should_behave_like 'self.instances', :home => '/opt/aem', :version => '5.6.1'
      end

      describe 'should support arbitrary home directory size' do

        let(:installs) { '/opt/aem/author/path/to/home/crx-quickstart/app/cq-quickstart-6.0.0-standalone.jar' }

        it_should_behave_like 'self.instances', :home => '/opt/aem/author/path/to/home', :version => '6.0.0'
      end

      describe 'should support v6.1 filename' do

        let(:installs) { '/opt/aem/crx-quickstart/app/cq-quickstart-6.1.0-standalone-launchpad.jar' }

        it_should_behave_like 'self.instances', :home => '/opt/aem', :version => '6.1.0'
      end
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
      expect(FileUtils).to receive(:remove_entry_secure).with('/opt/aem/crx-quickstart/repository')
      provider = @provider_class.new
      provider.resource = resource
      provider.destroy
    end

  end

  describe 'create' do

    shared_examples 'create_instance' do |opts|
      it {

        opts ||= { }

        if !opts[:user].nil? && !opts[:user].empty?
          expect(Etc).to receive(:getpwnam).with(opts[:user]).and_return(filestats)
          execute_options[:uid] = ugid
          resource[:user] = opts[:user]
        end

        if !opts[:group].nil? && !opts[:group].empty?
          expect(Etc).to receive(:getgrnam).with(opts[:group]).and_return(filestats)
          execute_options[:gid] = ugid
          resource[:group] = opts[:group]
        end

        # Starts the system
        expect(provider).to receive(:execute).with(/start/, execute_options).and_return(0)

        if opts[:context_root]
          uri = URI.parse("http://localhost:#{resource[:port]}/#{resource[:context_root]}/")
        else
          uri = URI.parse("http://localhost:#{resource[:port]}/")
        end

        # Monitor System for on
        expect(Net::HTTP).to receive(:get_response).with(uri).ordered.once.and_return(mock_response)

        expect(mock_response).to receive(:is_a?).ordered.twice.and_return(false)

        expect(Net::HTTP).to receive(:get_response).with(uri).ordered.once.and_return(mock_response)

        if (opts[:redirect])
          expect(mock_response).to receive(:is_a?).ordered.and_return(false)
        end
        expect(mock_response).to receive(:is_a?).ordered.and_return(true)

        # Stop System
        expect(provider).to receive(:execute).with(/stop/, execute_options).and_return(0)

        # Monitor System for off
        expect(Net::HTTP).to receive(:get_response).with(uri).ordered.once.and_return(mock_response)
        if (opts[:redirect])
          expect(mock_response).to receive(:is_a?).ordered.and_return(false)
        end
        expect(mock_response).to receive(:is_a?).ordered.and_return(true)

        expect(Net::HTTP).to receive(:get_response).with(uri).ordered.once.and_raise(exception)

        provider.create

      }
    end

    describe 'creates instance as root' do
      it_should_behave_like 'create_instance'
    end

    describe 'creates instance as a user' do
      it_should_behave_like 'create_instance', :user => 'aem'
    end

    describe 'creates instance as a group' do
      it_should_behave_like 'create_instance', :group => 'aem'
    end

    describe 'creates instance as a user/group' do
      it_should_behave_like 'create_instance', :user => 'aem', :group => 'aem'
    end

    describe 'supports non default port' do
      let(:resource) do
        Puppet::Type.type(:aem_installer).new({
          :name         => 'aem',
          :ensure       => :present,
          :version      => '6.1',
          :home         => '/opt/aem',
          :provider     => 'default',
          :port         => 8080,
          :snooze       => 0,
        })
      end
      it_should_behave_like 'create_instance'
    end

    describe 'supports using context root for URI' do
      let(:resource) do
        Puppet::Type.type(:aem_installer).new({
          :name         => 'aem',
          :context_root => 'contextroot',
          :ensure       => :present,
          :version      => '6.1',
          :home         => '/opt/aem',
          :provider     => 'default',
          :snooze       => 0,
        })
      end
      it_should_behave_like 'create_instance', :context_root => 'contextroot'
    end

    describe 'creates instance with redirect for monitor' do
      it_should_behave_like 'create_instance', :redirect => true
    end

    describe 'monitor timeout' do
      let(:resource) do
        allow(File).to receive(:file?).with(any_args).and_call_original
        allow(File).to receive(:directory?).with(any_args).and_call_original
        Puppet::Type.type(:aem_installer).new({
          :name     => 'aem',
          :ensure   => :present,
          :version  => '6.1',
          :home     => '/opt/aem',
          :provider => 'default',
          :snooze   => 3,
          :timeout  => 1,
        })
      end

      it 'should throw error when monitor timeout occurs' do

        # Starts the system
        expect(provider).to receive(:execute).with(/start/, execute_options).and_return(0)

        # Monitor System for on
        expect(Net::HTTP).to receive(:get_response) do |uri|
          uri.path == "http://localhost:#{resource[:port]}"
        end.once.ordered.and_return(mock_response)
        expect(mock_response).to receive(:is_a?).twice.and_return(false)

        expect { provider.create }.to raise_error(Timeout::Error)
      end
    end

  end

end
