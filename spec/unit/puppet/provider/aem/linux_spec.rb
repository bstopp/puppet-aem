#!/usr/bin/evn ruby

require 'spec_helper'

describe Puppet::Type.type(:aem).provider(:linux) do

  let(:source) { '/opt/aem/cq-author-4502.jar' }
  let (:install_name) { 'cq-quickstart-*-standalone*.jar' }

  let(:installs) { '/opt/aem/crx-quickstart/app/cq-quickstart-6.0.0-standalone.jar' }

  before :each do
    described_class.stubs(:which).with('find').returns('/bin/find')
    described_class.stubs(:which).with('java').returns('/usr/bin/java')
  end

  let(:resource) do
    allow(File).to receive(:file?).with(any_args).at_least(1).and_call_original
    expect(File).to receive(:file?).with(source).and_return(true)
    allow(File).to receive(:directory?).with(any_args).at_least(1).and_call_original
    expect(File).to receive(:directory?).with('/opt/aem').and_return(true)
    Puppet::Type.type(:aem).new({
      :name     => 'aem',
      :ensure   => :present,
      :source   => source,
      :version  => '6.1',
      :home     => '/opt/aem',
      :provider => 'linux',
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

  let(:failed_response) do
    class MockResponse
      def code
        500
      end
    end
    MockResponse.new
  end

  let(:success_response) do
    class MockResponse
      def code
        200
      end
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

        props = {
          :name             => opts[:home],
          :home             => opts[:home],
          :version          => '6.0.0',
          :ensure           => :present,
          :user             => 'aem',
          :group            => 'aem',
          :sample_content   => :true,
        }


        props[:version] = opts[:version] if opts[:version]

        envfile = File.join(opts[:home], 'crx-quickstart', 'bin', 'start-env')
        expect(File).to receive(:file?).with(envfile).and_return(true)
        expect(File).to receive(:readable?).with(envfile).and_return(true)

        envcontents = "\n"
        if opts[:env]
          if opts[:env][:port]
            envcontents << "PORT=#{opts[:env][:port]}\n"
            props.store(:port, opts[:env][:port])
          end

          if opts[:env][:type]
            envcontents << "TYPE=#{opts[:env][:type]}\n"
            props.store(:type, opts[:env][:type].intern)
          end

          if opts[:env][:runmodes]
            envcontents << "RUNMODES=#{opts[:env][:runmodes]}\n"
            props[:runmodes] = opts[:env][:runmodes].split(',')
          end

          if opts[:env][:jvm_mem_opts]
            envcontents << "JVM_MEM_OPTS='#{opts[:env][:jvm_mem_opts]}'\n"
            props[:jvm_mem_opts] = opts[:env][:jvm_mem_opts]
          end

          if opts[:env][:context_root]
            envcontents << "CONTEXT_ROOT='#{opts[:env][:context_root]}'\n"
            props[:context_root] = opts[:env][:context_root]
          end

          if opts[:env][:sample_content] == :false
            envcontents << "SAMPLE_CONTENT=#{Puppet::Provider::AEM::NO_SAMPLE_CONTENT}\n"
            props[:sample_content] = opts[:env][:sample_content]
          end

        end

        expect(File).to receive(:read).with(envfile).and_return(envcontents)
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

    describe 'should support empty env file ' do

      it_should_behave_like 'self.instances', :home => '/opt/aem', :env => { }
    end

    describe 'should support env file with port' do

      envprops  = { :port => 5 }
      it_should_behave_like 'self.instances', :home => '/opt/aem', :env => envprops
    end

    describe 'should support env file with type' do

      envprops  = { :type => :author }
      it_should_behave_like 'self.instances', :home => '/opt/aem', :env => envprops
    end

    describe 'should support env file with runmodes' do

      envprops  = { :runmodes => 'do,ray,me,fa' }
      it_should_behave_like 'self.instances', :home => '/opt/aem', :env => envprops
    end

    describe 'should support env file with jvm_mem_opts' do

      envprops  = { :jvm_mem_opts => 'some arbitrary memory value' }
      it_should_behave_like 'self.instances', :home => '/opt/aem', :env => envprops
    end

    describe 'should support env file with contentx_root' do

      envprops  = { :context_root => 'thisisthecontextroot' }
      it_should_behave_like 'self.instances', :home => '/opt/aem', :env => envprops
    end

    describe 'should support env file with no sample content' do
      envprops = { :sample_content => :false }
      it_should_behave_like 'self.instances', :home => '/opt/aem', :env => envprops
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
          userid = ugid
        end

        if !opts[:group].nil? && !opts[:group].empty?
          expect(Etc).to receive(:getgrnam).with(opts[:group]).and_return(filestats)
          execute_options[:gid] = ugid
          resource[:group] = opts[:group]
          groupid = ugid
        end

        # Unpacks the jar file
        expect(provider).to receive(:execute).with(['/usr/bin/java','-jar', source, '-b', resource[:home], '-unpack'],
        execute_options).and_return(0)

        # Creates the env file
        expect(Puppet::Parser::Files).to receive(:find_template).and_return('templates/start-env.erb')
        envfile = File.join(resource[:home], 'crx-quickstart', 'bin', 'start-env')

        expect(File).to receive(:new).with(envfile, any_args).and_return(mock_file)
        expect(mock_file).to receive(:write).and_return(0)
        expect(mock_file).to receive(:close)

        expect(File).to receive(:chmod).with(0750, any_args).and_return(0)
        expect(File).to receive(:chown).with(userid, groupid, any_args)

        # Creates start script
        expect(File).to receive(:rename).with(/start/,/start-orig/).and_return(0)

        expect(Puppet::Parser::Files).to receive(:find_template).and_return('templates/start.erb')
        startfile = File.join(resource[:home], 'crx-quickstart', 'bin', 'start')
        expect(File).to receive(:new).with(startfile, any_args).and_return(mock_file)
        expect(mock_file).to receive(:write).and_return(0)
        expect(mock_file).to receive(:close)

        expect(File).to receive(:chmod).with(0750, any_args).and_return(0)
        expect(File).to receive(:chown).with(userid, groupid, any_args)

        # Starts the system
        expect(provider).to receive(:execute).with(/start/, execute_options).and_return(0)

        # Monitor System for on
        expect(Net::HTTP).to receive(:get_response) do |uri|
          result = false
          if opts[:context_root]
            result = (uri.to_s == "http://localhost:#{resource[:port]}/#{resource[:context_root]}/")
          else
            result = (uri.to_s == "http://localhost:#{resource[:port]}/")
          end

          result || fail

        end.once.ordered.and_return(failed_response)

        expect(failed_response).to receive(:is_a?).twice.and_return(false)

        expect(Net::HTTP).to receive(:get_response) do |uri|
          result = false
          if opts[:context_root]
            result = (uri.to_s == "http://localhost:#{resource[:port]}/#{resource[:context_root]}/")
          else
            result = (uri.to_s == "http://localhost:#{resource[:port]}/")
          end

          result || fail

        end.once.ordered.and_return(success_response)

        if (opts[:redirect])
          expect(success_response).to receive(:is_a?).and_return(false)
        end
        expect(success_response).to receive(:is_a?).and_return(true)

        # Stop System
        expect(provider).to receive(:execute).with(/stop/, execute_options).and_return(0)

        # Monitor System for off
        expect(Net::HTTP).to receive(:get_response) do |uri|
          result = false
          if opts[:context_root]
            result = (uri.to_s == "http://localhost:#{resource[:port]}/#{resource[:context_root]}/")
          else
            result = (uri.to_s == "http://localhost:#{resource[:port]}/")
          end
          result || fail

        end.once.ordered.and_return(success_response)

        if (opts[:redirect])
          expect(success_response).to receive(:is_a?).and_return(false)
        end
        expect(success_response).to receive(:is_a?).and_return(true)

        expect(Net::HTTP).to receive(:get_response) do |uri|
          uri.path == "http://localhost:#{resource[:port]}"
        end.once.ordered.and_throw(exception)

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
        allow(File).to receive(:file?).with(any_args).and_call_original
        expect(File).to receive(:file?).with(source).and_return(true)
        allow(File).to receive(:directory?).with(any_args).and_call_original
        expect(File).to receive(:directory?).with('/opt/aem').and_return(true)
        Puppet::Type.type(:aem).new({
          :name         => 'aem',
          :ensure       => :present,
          :source       => source,
          :version      => '6.1',
          :home         => '/opt/aem',
          :provider     => 'linux',
          :port         => 8080,
          :snooze       => 0,
        })
      end
      it_should_behave_like 'create_instance'
    end

    describe 'supports using context root for URI' do
      let(:resource) do
        allow(File).to receive(:file?).with(any_args).and_call_original
        expect(File).to receive(:file?).with(source).and_return(true)
        allow(File).to receive(:directory?).with(any_args).and_call_original
        expect(File).to receive(:directory?).with('/opt/aem').and_return(true)
        Puppet::Type.type(:aem).new({
          :name         => 'aem',
          :ensure       => :present,
          :source       => source,
          :version      => '6.1',
          :home         => '/opt/aem',
          :provider     => 'linux',
          :snooze       => 0,
          :context_root => 'contextroot'
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
        expect(File).to receive(:file?).with(source).and_return(true)
        allow(File).to receive(:directory?).with(any_args).and_call_original
        expect(File).to receive(:directory?).with('/opt/aem').and_return(true)
        Puppet::Type.type(:aem).new({
          :name     => 'aem',
          :ensure   => :present,
          :source   => source,
          :version  => '6.1',
          :home     => '/opt/aem',
          :provider => 'linux',
          :snooze   => 3,
          :timeout  => 1,
        })
      end

      it 'should throw error when monitor timeout occurs' do

        # Unpacks the jar file
        expect(provider).to receive(:execute).with(['/usr/bin/java','-jar', source, '-b', resource[:home], '-unpack'],
        execute_options).and_return(0)

        # Creates the env file
        expect(Puppet::Parser::Files).to receive(:find_template).and_return('templates/start-env.erb')
        expect(File).to receive(:new).and_return(mock_file)
        expect(mock_file).to receive(:write).and_return(0)
        expect(mock_file).to receive(:close)
        expect(File).to receive(:chmod).with(0750, any_args).and_return(0)
        expect(File).to receive(:chown).with(any_args)

        # Creates start script
        expect(File).to receive(:rename).with(/start/,/start-orig/).and_return(0)
        expect(Puppet::Parser::Files).to receive(:find_template).and_return('templates/start.erb')
        expect(File).to receive(:new).and_return(mock_file)
        expect(mock_file).to receive(:write).and_return(0)
        expect(mock_file).to receive(:close)
        expect(File).to receive(:chmod).with(0750, any_args).and_return(0)
        expect(File).to receive(:chown).with(any_args)

        # Starts the system
        expect(provider).to receive(:execute).with(/start/, execute_options).and_return(0)

        # Monitor System for on
        expect(Net::HTTP).to receive(:get_response) do |uri|
          uri.path == "http://localhost:#{resource[:port]}"
        end.once.ordered.and_return(failed_response)
        expect(failed_response).to receive(:is_a?).twice.and_return(false)

        expect { provider.create }.to raise_error(Timeout::Error)
      end
    end

  end

end

