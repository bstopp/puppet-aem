#!/usr/bin/evn ruby

require 'spec_helper'

describe Puppet::Type.type(:aem).provider(:linux) do

  let(:source) { '/opt/aem/cq-author-4502.jar' }
  let (:install_name) { 'cq-quickstart-*-standalone*.jar' }

  before :each do
    #    Puppet::Util.stubs(:which).with('find').returns('/bin/find')
    described_class.stubs(:which).with('find').returns('/bin/find')
    #    Puppet::Util.stubs(:which).with('java').returns('/usr/bin/java')
    described_class.stubs(:which).with('java').returns('/usr/bin/java')
  end

  let(:resource) do
    expect(File).to receive(:exists?).with(source).and_return(true)
    expect(Dir).to receive(:exists?).with('/opt/aem').and_return(true)
    Puppet::Type.type(:aem).new({
      :name     => 'aem',
      :ensure   => :present,
      :source   => source,
      :version  => '6.1',
      :home     => '/opt/aem',
      :provider => 'linux',
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

  Stat = Struct.new(:uid, :gid)
  Id = Struct.new(:name)

  ugid = 2001
  filestats = Stat.new(ugid, ugid)
  id = Id.new('aem')

  describe 'self.instances' do

    let(:installs) do
      <<-FIND_OUTPUT
      /opt/aem/crx-quickstart/app/cq-quickstart-5.6.1-standalone.jar
      /opt/aem/author/crx-quickstart/app/cq-quickstart-6.0.0-standalone.jar
      /opt/aem/publish/crx-quickstart/app/cq-quickstart-6.1.0-standalone-launchpad.jar
      FIND_OUTPUT
    end

    it 'should have an instances method' do
      expect(described_class).to respond_to(:instances)
    end

    it 'returns an array of installs' do
      expect(Puppet::Util::Execution).to receive(:execpipe).with(['/bin/find', '/', "-name \"#{install_name}\"", '-type f']).and_yield(installs)

      expect(File).to receive(:stat).and_return(filestats).exactly(3).times
      expect(Etc).to receive(:getpwuid).with(ugid).and_return(id).exactly(3).times
      expect(Etc).to receive(:getgrgid).with(ugid).and_return(id).exactly(3).times

      installed = described_class.instances

      expect(installed[0].properties).to eq({
        :name     => '/opt/aem',
        :home     => '/opt/aem',
        :version  => '5.6.1',
        :ensure   => :present,
        :user     => 'aem',
        :group    => 'aem',
      })

      expect(installed[1].properties).to eq({
        :name     => '/opt/aem/author',
        :home     => '/opt/aem/author',
        :version  => '6.0.0',
        :ensure   => :present,
        :user     => 'aem',
        :group    => 'aem',
      })

      expect(installed.last.properties).to eq({
        :name     => '/opt/aem/publish',
        :home     => '/opt/aem/publish',
        :version  => '6.1.0',
        :ensure   => :present,
        :user     => 'aem',
        :group    => 'aem',
      })

    end
  end

  describe 'create' do

    shared_examples 'create_instance' do |opts|
      it {

        if !opts.nil? && !opts[:user].nil? && !opts[:user].empty?
          expect(Etc).to receive(:getpwnam).with(opts[:user]).and_return(filestats)
          execute_options[:uid] = ugid
          resource[:user] = opts[:user]
          userid = ugid
        end

        if !opts.nil? && !opts[:group].nil? && !opts[:group].empty?
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
        expect(File).to receive(:write) do |file, contents|
          # Add fields here when new properties are added to env file
          port = false
          type = false

          if /CQ_PORT=#{resource[:port]}/ =~ contents
            port = true
          end
          if /CQ_TYPE=#{resource[:type]}/ =~ contents
            type = true
          end

          expect(port && type).to be_truthy
        end.and_return(0)
        expect(File).to receive(:chmod).with(0750, any_args).and_return(0)
        expect(File).to receive(:chown).with(userid, groupid, any_args)

        # Creates start script
        expect(File).to receive(:rename).with(/start/,/start-orig/).and_return(0)
        expect(Puppet::Parser::Files).to receive(:find_template).and_return('templates/start-6.1.0.erb')
        expect(File).to receive(:write).and_return(0)
        expect(File).to receive(:chmod).with(0750, any_args).and_return(0)
        expect(File).to receive(:chown).with(userid, groupid, any_args)

        # Starts the system
        expect(provider).to receive(:execute).with(/start/, execute_options).and_return(0)

        # Monitor System
        #TODO Figure out why this doesn't work with two responses.
        # expect(http).to receive(:get_response).with(any_args).once.ordered.and_return(failed_response)
        expect(Net::HTTP).to receive(:get_response) do |uri|
          uri.path == "http://localhost:#{resource[:port]}"
        end.once.ordered.and_return(success_response)

        # Stop System
        expect(provider).to receive(:execute).with(/stop/, execute_options).and_return(0)

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
        expect(File).to receive(:exists?).with(source).and_return(true)
        expect(Dir).to receive(:exists?).with('/opt/aem').and_return(true)
        Puppet::Type.type(:aem).new({
          :name     => 'aem',
          :ensure   => :present,
          :source   => source,
          :version  => '6.1',
          :home     => '/opt/aem',
          :provider => 'linux',
          :port => 8080,
        })
      end
      it_should_behave_like 'create_instance'
    end

    describe 'creates config file with values' do
      let(:resource) do
        expect(File).to receive(:exists?).with(source).and_return(true)
        expect(Dir).to receive(:exists?).with('/opt/aem').and_return(true)
        Puppet::Type.type(:aem).new({
          :name     => 'aem',
          :ensure   => :present,
          :source   => source,
          :version  => '6.1',
          :home     => '/opt/aem',
          :provider => 'linux',
          :port     => 8080,
          :type     => :author,
        })
      end
      it_should_behave_like 'create_instance'
    end
  end

end

