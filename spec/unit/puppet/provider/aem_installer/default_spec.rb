require 'spec_helper'

describe Puppet::Type.type(:aem_installer).provider(:default) do

  let(:install_name) { 'cq-quickstart-*-standalone*.jar' }

  let(:installs) { '/opt/aem/crx-quickstart/app/cq-quickstart-6.0.0-standalone.jar' }

  let(:resource) do
    allow(File).to receive(:file?).with(any_args).at_least(1).and_call_original
    allow(File).to receive(:directory?).with(any_args).at_least(1).and_call_original
    Puppet::Type.type(:aem_installer).new(
      :name     => 'aem',
      :ensure   => :present,
      :home     => '/opt/aem',
      :provider => 'default',
      :snooze   => 0
    )
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
      :custom_environment     => {}
    }
  end

  let(:mock_success_resp) do
    class MockSuccessResp < Net::HTTPSuccess
      def initialize
      end
    end
    MockSuccessResp.new
  end

  let(:mock_redirect_resp) do
    class MockRedirectResp < Net::HTTPRedirection
      def initialize
      end
    end
    MockRedirectResp.new
  end

  let(:mock_unavailable_resp) do
    class MockUnavailableResp < Net::HTTPServiceUnavailable
      def initialize
      end
    end
    MockUnavailableResp.new
  end

  let(:mock_unauthorized_resp) do
    class MockUnauthorizedResp < Net::HTTPUnauthorized
      def initialize
      end
    end
    MockUnauthorizedResp.new
  end

  let(:exception) do
    Errno::ECONNREFUSED.new
  end

  let(:mock_file) { double('File') }

  FileStat = Struct.new(:uid, :gid)
  UserStat = Struct.new(:uid, :name)
  GroupStat = Struct.new(:gid, :name)
  ugid = 2001


  before do
    @provider_class = described_class
    @provider_class.stubs(:suitable?).returns true
    Puppet::Type.type(:aem_installer).stubs(:defaultprovider).returns @provider_class

  end

  before :each do
    described_class.stubs(:which).with('find').returns('/bin/find')
    described_class.stubs(:which).with('java').returns('/usr/bin/java')
  end

  describe 'exists?' do

    shared_examples 'exists_check' do |opts|
      it do

        filestat = FileStat.new(ugid, ugid)
        userstat = UserStat.new(ugid, 'aem')
        groupstat = GroupStat.new(ugid, 'aem')

        provider = @provider_class.new(opts[:resource])
        if opts[:present]
          yielddata = '/opt/aem/crx-quickstart/app/cq-quickstart-6.1.0-standalone-quickstart.jar'
        else
          yielddata = '';
        end
        expect(provider).to receive(:execpipe).and_yield(yielddata)

        if opts[:present]
          expect(File).to receive(:stat).with(yielddata).and_return(filestat) if opts[:present]
          expect(File).to receive(:exist?).with('/opt/aem/crx-quickstart/repository').and_return(true)
          expect(Etc).to receive(:getpwuid).with(ugid).and_return(userstat)
          expect(Etc).to receive(:getgrgid).with(ugid).and_return(groupstat)

          expect(File).to receive(:foreach).with('/opt/aem/crx-quickstart/bin/start-env').and_yield("")
        end

        expect(provider.exists?).to eq(opts[:present])
      end
    end

    describe 'ensure is absent' do
      resource = Puppet::Type.type(:aem_installer).new(
          :name     => 'aem',
          :ensure   => :absent,
          :home     => '/opt/aem',
          :provider => 'default',
          :snooze   => 0
        )
      it_should_behave_like 'exists_check', :resource => resource, :ensure => :absent, :present => false
    end

    describe 'ensure is present' do
      resource = Puppet::Type.type(:aem_installer).new(
          :name     => 'aem',
          :ensure   => :present,
          :home     => '/opt/aem',
          :provider => 'default',
          :snooze   => 0
        )
      it_should_behave_like 'exists_check', :resource => resource, :ensure => :present, :present => true
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
      it do

        opts ||= {}

        opts[:user] ||= 'root'
        opts[:group] ||= 'root'
        opts[:port] ||= 4502

        filestat = FileStat.new(ugid, ugid)
        userstat = UserStat.new(ugid, opts[:user])
        groupstat = GroupStat.new(ugid, opts[:group])

        crline = "CONTEXT_ROOT='#{opts[:context_root]}'" if opts[:context_root]
        envdata = <<-EOF
PORT=#{opts[:port]}
#{crline}
        EOF

        quickstartfile = '/opt/aem/crx-quickstart/app/cq-quickstart-6.1.0-standalone-quickstart.jar'
        expect(provider).to receive(:execpipe).and_yield(quickstartfile)
        expect(File).to receive(:stat).with(quickstartfile).and_return(filestat)
        expect(Etc).to receive(:getpwuid).with(ugid).and_return(userstat)
        expect(Etc).to receive(:getgrgid).with(ugid).and_return(groupstat)
        expect(File).to receive(:foreach).with('/opt/aem/crx-quickstart/bin/start-env').and_yield(envdata)

        expect(Etc).to receive(:getpwnam).with(opts[:user]).and_return(userstat)
        execute_options[:uid] = ugid

        expect(Etc).to receive(:getgrnam).with(opts[:group]).and_return(groupstat)
        execute_options[:gid] = ugid

        # Starts the system
        expect(provider).to receive(:execute).with(/start/, execute_options).and_return(0)

        if opts[:context_root]
          uri = URI.parse("http://localhost:#{opts[:port]}/#{opts[:context_root]}/")
        else
          uri = URI.parse("http://localhost:#{opts[:port]}/")
        end


        # Monitor System for on
        expect(Net::HTTP).to receive(:get_response).with(uri).ordered.once.and_return(mock_unavailable_resp)

        opts[:redirect] ||= mock_success_resp
        expect(Net::HTTP).to receive(:get_response).with(uri).ordered.once.and_return(opts[:response_type])

        # Stop System
        expect(provider).to receive(:execute).with(/stop/, execute_options).and_return(0)

        # Monitor System for off
        expect(Net::HTTP).to receive(:get_response).with(uri).ordered.once.and_return(mock_success_resp)

        expect(Net::HTTP).to receive(:get_response).with(uri).ordered.once.and_raise(exception)

        provider.exists?
        provider.create

      end
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
        Puppet::Type.type(:aem_installer).new(
          :name         => 'aem',
          :ensure       => :present,
          :home         => '/opt/aem',
          :provider     => 'default',
          :snooze       => 0
        )
      end
      it_should_behave_like 'create_instance', :port => '8080'
    end

    describe 'supports using context root for URI' do
      let(:resource) do
        Puppet::Type.type(:aem_installer).new(
          :name         => 'aem',
          :ensure       => :present,
          :home         => '/opt/aem',
          :provider     => 'default',
          :snooze       => 0
        )
      end
      it_should_behave_like 'create_instance', :context_root => 'contextroot'
    end

    describe 'creates instance with redirect for monitor' do
      it_should_behave_like 'create_instance', :response_type => :mock_redirect_resp
    end

    describe 'creates instance with unauthorized for monitor' do
      it_should_behave_like 'create_instance', :response_type => :mock_unauthorized_resp
    end

    describe 'monitor timeout' do
      let(:resource) do
        allow(File).to receive(:file?).with(any_args).and_call_original
        allow(File).to receive(:directory?).with(any_args).and_call_original
        Puppet::Type.type(:aem_installer).new(
          :name     => 'aem',
          :ensure   => :present,
          :home     => '/opt/aem',
          :provider => 'default',
          :snooze   => 3,
          :timeout  => 1
        )
      end

      it 'should throw error when monitor timeout occurs' do

        user = 'root'
        filestat = FileStat.new(ugid, ugid)
        userstat = UserStat.new(ugid, user)
        groupstat = GroupStat.new(ugid, user)

        envdata = <<-EOF
PORT=4502
        EOF

        quickstartfile = '/opt/aem/crx-quickstart/app/cq-quickstart-6.1.0-standalone-quickstart.jar'
        expect(provider).to receive(:execpipe).and_yield(quickstartfile)
        expect(File).to receive(:stat).with(quickstartfile).and_return(filestat)
        expect(Etc).to receive(:getpwuid).with(ugid).and_return(userstat)
        expect(Etc).to receive(:getgrgid).with(ugid).and_return(groupstat)
        expect(File).to receive(:foreach).with('/opt/aem/crx-quickstart/bin/start-env').and_yield(envdata)

        expect(Etc).to receive(:getpwnam).with(user).and_return(userstat)
        execute_options[:uid] = ugid

        expect(Etc).to receive(:getgrnam).with(user).and_return(groupstat)
        execute_options[:gid] = ugid
        provider.exists?

        # Starts the system
        expect(provider).to receive(:execute).with(/start/, execute_options).and_return(0)

        # Monitor System for on
        uri = URI("http://localhost:4502/")
        expect(Net::HTTP).to receive(:get_response).with(uri).ordered.once.and_return(mock_unavailable_resp)
        expect { provider.create }.to raise_error(Timeout::Error)
      end
    end

  end

end
