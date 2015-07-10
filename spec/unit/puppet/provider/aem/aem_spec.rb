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

  Stat = Struct.new(:uid, :gid)
  Id = Struct.new(:name)

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
    provider_class.stubs(:which).with('java').returns('/usr/bin/java')
  end


  describe 'self.instances' do

    it 'should have an instances method' do
      expect(described_class).to respond_to(:instances)
    end

    it 'returns an array of installs' do
      expect(Puppet::Util::Execution).to receive(:execpipe).with(['/bin/find', '/', "-name \"#{install_name}\"", '-type f']).and_yield(installs)

      filestats = Stat.new("1001", "1001") 
      id = Id.new('aem')

      expect(File).to receive(:stat).and_return(filestats).exactly(3).times
      expect(Etc).to receive(:getpwuid).with("1001").and_return(id).exactly(3).times
      expect(Etc).to receive(:getgrgid).with("1001").and_return(id).exactly(3).times

      installed = provider_class.instances

      expect(installed[0].properties).to eq(
        {
          :name     => '/opt/aem',
          :home     => '/opt/aem',
          :version  => '5.6.1',
          :ensure   => :present,
          :user     => 'aem',
          :group    => 'aem',
        }
      )
      expect(installed[1].properties).to eq(
        {
          :name     => '/opt/aem/author',
          :home     => '/opt/aem/author',
          :version  => '6.0.0',
          :ensure   => :present,
          :user     => 'aem',
          :group    => 'aem',
        }
      )
      expect(installed.last.properties).to eq(
        {
          :name     => '/opt/aem/publish',
          :home     => '/opt/aem/publish',
          :version  => '6.1.0',
          :ensure   => :present,
          :user     => 'aem',
          :group    => 'aem',
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

    let(:environment) do
      Puppet::Node::Environment.create(:test, []) 
    end
    
    shared_examples 'create_instance' do |opts|
      it {
        exec = class_double("Puppet::Util::Execution").as_stubbed_const

        expect(exec).to receive(:execute).with(
          ['/usr/bin/java','-jar', source, '-b', aem_res[:home], '-unpack'], execute_options
          ).once.ordered.and_return(0)

        expect(File).to receive(:rename).with(/start/, /start-orig/).and_return(0)
        expect(Puppet).to receive(:lookup).with(:environments).and_return({:production => environment})
        expect(Puppet::Parser::Files).to receive(:find_template).with(/start-6.1.0/, environment).and_return("/path/to/file.erb")
        expect(File).to receive(:read).with('/path/to/file.erb')
        expect(exec).to receive(:execute).with('/opt/aem/crx-quickstart/bin/start').once.ordered.and_return(0)

        http = class_double("Net::HTTP").as_stubbed_const
        
        #TODO Figure out why this doesn't work with two responses.
        expect(http).to receive(:get_response).with(URI.parse("http://localhost:4502")).ordered.and_return(success_response)

#        expect(http).to receive(:get_response).and_return(failed_response, success_response)
#        expect(http).to receive(:get_response) do |uri|
#          uri.path == "http://localhost:4502"
#          true
#        end.once.ordered.and_return(failed_response)
#        expect(http).to receive(:get_response) do |uri|
#          uri.path == "http://localhost:4502"
#          true
#        end.once.ordered.and_return(success_response)

        expect(exec).to receive(:execute).with('/opt/aem/crx-quickstart/bin/stop').once.ordered.and_return(0)

        provider.create

      }
    end

    let(:aem_res) do
      expect(File).to receive(:exists?).with(source).and_return(true)
      expect(Dir).to receive(:exists?).with('/opt/aem').and_return(true)
      Puppet::Type.type(:aem).new({
        :name     => 'myaem',
        :ensure   => :present,
        :home     => '/opt/aem',
        :source   => source,
      })
    end

    describe 'creates instance as root' do
      it_should_behave_like 'create_instance'
    end
    

    context 'specified user' do
#      let(:aem_res) do
#        expect(File).to receive(:exists?).with(source).and_return(true)
#        expect(Dir).to receive(:exists?).with('/opt/aem').and_return(true)
#        Puppet::Type.type(:aem).new({
#          :name     => 'myaem',
#          :ensure   => :present,
#          :home     => '/opt/aem',
#          :source   => source,
#          :user     => 'aem',
#          :group    => 'aem',
#        })
#      end
#      
#      let(:execute_options) do
#        {
#          :failonfail             => true, 
#          :combine                => true, 
#          :custom_environment     => {},
#          :uid                    => '1001',
#          :gid                    => '1001',
#        }
#      end
#
#      it 'creates the AEM instance as a specified user' do
#        Opts = Struct.new(:uid, :gid)
#
#        struct = Opts.new('1001', '1001')
#
#        
#        expect(Etc).to receive(:getpwnam).with('aem').and_return(struct)
#        expect(Etc).to receive(:getgrnam).with('aem').and_return(struct)
#
#        expect(Puppet::Util::Execution).to receive(:execute).with(
#          ['/usr/bin/java','-jar', source, '-b', aem_res[:home], '-unpack'], execute_options
#          ).and_return(0)
#
##        expect(File).to receive(:rename).with(
##          '/opt/aem/crx-quickstart/bin/start', '/opt/aem/crx-quickstart/bin/start-orig')
#
#        provider.create
#      end
    end
  end

  
  
  describe '#destroy' do

    let(:aem_res) do
      expect(File).to receive(:exists?).with(source).and_return(true)
      expect(Dir).to receive(:exists?).with('/opt/aem').and_return(true)
      Puppet::Type.type(:aem).new({
        :name     => 'myaem',
        :ensure   => :present,
        :home     => '/opt/aem',
        :source   => source,
      })
    end
    
    it 'deletes the home directory' do
      expect(Puppet::Util::Execution).to receive(:execute).with(
        ['/bin/find', ['/opt/aem', "-name \"#{install_name}\"", '-type f']], execute_options
        ).and_return("/opt/aem/crx-quickstart/app/cq-quickstart-5.6.1-standalone.jar\n")

      expect(FileUtils).to receive(:remove_entry_secure).with('/opt/aem/crx-quickstart')

      filestats = Stat.new("1001", "1001") 
      id = Id.new('aem')

      expect(File).to receive(:stat).and_return(filestats)
      expect(Etc).to receive(:getpwuid).with("1001").and_return(id)
      expect(Etc).to receive(:getgrgid).with("1001").and_return(id)

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

