require 'spec_helper'

describe Puppet::Type.type(:aem_osgi_config).provider(:ruby) do

  let(:bundle_location)do
    'launchpad:resources/install/999/com.bundle.filename.jar'
  end

  let(:resource) do
    Puppet::Type.type(:aem_osgi_config).new(
      :name           => 'OsgiConfig',
      :ensure         => :present,
      :configuration  => {
        'boolean' => false,
        'long'    => 123456789,
        'string'  => 'string',
      },
      :handle_missing => :merge,
      :home           => '/opt/aem',
      :password       => 'admin',
      :timeout        => 1,
      :username       => 'admin'
    )
  end

  let(:provider) do
    provider = described_class.new(resource)
    provider
  end

  let(:mock_response) do
    class MockResponse
    end
    MockResponse.new
  end

  let(:config_data) do
    data = <<-JSON
      [
        {
          "pid" : "#{resource[:name]}",
          "bundle_location": "#{bundle_location}",
          "properties" : {
            "boolean" : {
              "is_set": true,
              "value" : false
            },
            "long" : {
              "is_set": true,
              "value" : 123456789
            },
            "string" : {
              "is_set": true,
              "value" : "string"
            },
            "array" : {
              "is_set": false,
              "values" : [
                "this",
                "is",
                "an",
                "array"
              ]
            },
            "propertynotset" : {
              "is_set": false,
              "value" : "shouldnotbehere"
            }
          }
        }
      ]
    JSON
    data
  end

  let(:exception) do
    Errno::ECONNREFUSED.new
  end

  describe 'exists?' do

    shared_examples 'exists_check' do |opts|
      it do

        WebMock.reset!

        opts ||= {}
        opts[:port] ||= 4502

        crline = "CONTEXT_ROOT='#{opts[:context_root]}'" if opts[:context_root]
        envdata = <<-EOF
PORT=#{opts[:port]}
#{crline}
        EOF

        expect(File).to receive(:foreach).with('/opt/aem/crx-quickstart/bin/start-env').and_yield(envdata)

        if opts[:context_root]
          uri_s = "http://localhost:#{opts[:port]}/#{opts[:context_root]}"
        else
          uri_s = "http://localhost:#{opts[:port]}"
        end
        uri_s = "#{uri_s}/system/console/configMgr/#{resource[:name]}.json"
        uri = URI(uri_s)

        status = opts[:present] ? 200 : 500

        get_stub = stub_request(
          :get, "#{uri.scheme}://admin:admin@#{uri.host}:#{uri.port}#{uri.path}"
        ).to_return(:status => status,:body => config_data)

        expect(provider.exists?).to eq(opts[:present])
        #expect(get_stub).to have_been_requested

        if opts[:present]
          configuration = provider.configuration
          expect(configuration).to_not eq(:absent)
          expect(configuration['boolean']).to eq(false)
          expect(configuration['long']).to eq(123456789)
          expect(configuration['string']).to eq('string')
        end

      end
    end

    describe 'ensure is absent' do

      it_should_behave_like 'exists_check', :present => false
    end

    describe 'ensure is present' do
      it_should_behave_like 'exists_check', :present => true
    end

    describe 'ensure is present with context root' do
      it_should_behave_like 'exists_check', :present => true, :context_root => 'contextroot'
    end

  end

  describe 'flush' do
    shared_examples 'flush_posts' do |opts|
      it do
        WebMock.reset!

        opts ||= {}
        opts[:port] ||= 4502

        crline = "CONTEXT_ROOT='#{opts[:context_root]}'" if opts[:context_root]
        envdata = <<-EOF
PORT=#{opts[:port]}
#{crline}
        EOF

        expect(File).to receive(:foreach).with('/opt/aem/crx-quickstart/bin/start-env').and_yield(envdata)

        if opts[:context_root]
          uri_s = "http://localhost:#{opts[:port]}/#{opts[:context_root]}"
        else
          uri_s = "http://localhost:#{opts[:port]}"
        end
        uri_s = "#{uri_s}/system/console/configMgr/#{resource[:name]}.json"
        uri = URI(uri_s)


        status = opts[:present] ? 200 : 500

        get_stub = stub_request(
          :get, "#{uri.scheme}://admin:admin@#{uri.host}:#{uri.port}#{uri.path}"
        ).to_return(:status => status, :body => config_data)

        expected_params = opts[:post_params].merge('apply' => 'true')
        expected_params['$location'] = bundle_location if opts[:present]

        post_stub = stub_request(
          :post, 'http://admin:admin@localhost:4502/system/console/configMgr/OsgiConfig'
        ).with(
            :body => expected_params,
            :headers => {
              'Accept'=>'*/*',
              'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'Content-Type'=>'application/x-www-form-urlencoded',
              'Host'=>'localhost:4502',
              'Referer'=>'http://localhost:4502/system/console/configMgr',
              'User-Agent'=>'Ruby'
            }
        ).to_return(:status => 200)

        # Populate property hash
        provider.exists?

        if opts[:destroy]
          provider.destroy
          times = 1
        else
          provider.create
          times = 2
        end

        expect{ provider.flush }.to_not raise_error
        expect(get_stub).to have_been_requested.times(times)
        expect(post_stub).to have_been_requested
      end
    end

    describe 'create' do
      let(:resource) do
        Puppet::Type.type(:aem_osgi_config).new(
          :name           => 'OsgiConfig',
          :ensure         => :present,
          :configuration  => {
            'boolean' => true,
            'long'    => 987654321,
            'string'  => 'string'
          },
          :handle_missing => :merge,
          :home           => '/opt/aem',
          :password       => 'admin',
          :timeout        => 1,
          :username       => 'admin'
        )
      end

      it_should_behave_like 'flush_posts',
        :present => false,
        :post_params => {
          'propertylist' => 'boolean,long,string',
          'boolean'      => 'true',
          'long'         => '987654321',
          'string'       => 'string'
        }
    end

    describe 'destroy' do
      it_should_behave_like 'flush_posts', 
        :present     => false, 
        :destroy     => true,
        :post_params => { 
          'delete' => 'true'
        }
    end

    describe 'update with remove' do
      let(:resource) do
        Puppet::Type.type(:aem_osgi_config).new(
          :name           => 'OsgiConfig',
          :ensure         => :present,
          :configuration  => {
            'boolean' => true,
            'long'    => 987654321
          },
          :handle_missing => :remove,
          :home           => '/opt/aem',
          :password       => 'admin',
          :timeout        => 1,
          :username       => 'admin'
        )
      end
      it_should_behave_like 'flush_posts',
        :present     => true,
        :post_params => {
          'propertylist' => 'boolean,long',
          'boolean' => 'true',
          'long'    => '987654321'
      }

    end

    describe 'update with merge' do
      let(:resource) do
        Puppet::Type.type(:aem_osgi_config).new(
          :name           => 'OsgiConfig',
          :ensure         => :present,
          :configuration  => {
            'long'  => 987654321,
          },
          :handle_missing => :merge,
          :home           => '/opt/aem',
          :password       => 'admin',
          :timeout        => 1,
          :username       => 'admin'
        )
      end

      it_should_behave_like 'flush_posts',
        :present => true,
        :post_params => {
          'propertylist' => 'boolean,long,string',
          'boolean' => 'false',
          'long'    => '987654321',
          'string'  => 'string',
        }
    end

    describe 'create with array because webmock has issues matching array in a hash for parameters' do
      let(:resource) do
        Puppet::Type.type(:aem_osgi_config).new(
          :name           => 'OsgiConfig',
          :ensure         => :present,
          :configuration  => {
            'boolean' => false,
            'long'    => 123456789,
            'string'  => 'string',
            'array'   => ['this', 'is', 'an', 'array']
          },
          :handle_missing => :merge,
          :home           => '/opt/aem',
          :password       => 'admin',
          :timeout        => 1,
          :username       => 'admin'
        )
      end

      it 'should work without errors' do
        WebMock.reset!

        envdata = <<-EOF
PORT=4502
        EOF

        expect(File).to receive(:foreach).with('/opt/aem/crx-quickstart/bin/start-env').and_yield(envdata)

        uri_s = "http://localhost:4502/system/console/configMgr/#{resource[:name]}.json"
        uri = URI(uri_s)

        expected_params = 'boolean=false&long=123456789&string=string&array=this&array=is&array=an&array=array'
        expected_params += '&propertylist=boolean%2Clong%2Cstring%2Carray&apply=true'
        get_stub = stub_request(
          :get, "#{uri.scheme}://admin:admin@#{uri.host}:#{uri.port}#{uri.path}"
        ).to_return(:status => 500, :body => config_data)

        post_stub = stub_request(
          :post, 'http://admin:admin@localhost:4502/system/console/configMgr/OsgiConfig'
        ).with(
            :body => expected_params,
            :headers => {
              'Accept'=>'*/*',
              'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'Content-Type'=>'application/x-www-form-urlencoded',
              'Host'=>'localhost:4502',
              'Referer'=>'http://localhost:4502/system/console/configMgr',
              'User-Agent'=>'Ruby'
            }
        ).to_return(:status => 200)

        # Populate property hash
        provider.exists?
        provider.create
        expect{ provider.flush }.to_not raise_error
        expect(get_stub).to have_been_requested.times(2)
        expect(post_stub).to have_been_requested

      end
    end

    describe 'flush post errors' do
      it 'should generate an error' do
        WebMock.reset!

        envdata = <<-EOF
PORT=4502
        EOF

        expect(File).to receive(:foreach).with('/opt/aem/crx-quickstart/bin/start-env').and_yield(envdata)

        uri_s = 'http://localhost:4502'
        uri_s = "#{uri_s}/system/console/configMgr/#{resource[:name]}.json"
        uri = URI(uri_s)

        get_stub = stub_request(
          :get, "#{uri.scheme}://admin:admin@#{uri.host}:#{uri.port}#{uri.path}"
        ).to_return(:status => 200, :body => config_data)

        post_stub = stub_request(
          :post, 'http://admin:admin@localhost:4502/system/console/configMgr/OsgiConfig'
        ).with(
            :body =>  { 
              'delete'       => 'true',
              'apply'        => 'true',
            }
        ).to_return(:status => 500)

        # Populate property hash
        provider.exists?
        provider.destroy
        expect{ provider.flush }.to raise_error(/500/)
        expect(get_stub).to have_been_requested
        expect(post_stub).to have_been_requested
      end
    end

    describe 'aem not running' do
      it 'should generate an error' do
        WebMock.reset!

        envdata = <<-EOF
PORT=4502
        EOF

        expect(File).to receive(:foreach).with('/opt/aem/crx-quickstart/bin/start-env').and_yield(envdata)

        uri_s = 'http://localhost:4502'
        uri_s = "#{uri_s}/system/console/configMgr/#{resource[:name]}.json"
        uri = URI(uri_s)

        get_stub = stub_request(
          :get, "#{uri.scheme}://admin:admin@#{uri.host}:#{uri.port}#{uri.path}"
        ).to_timeout

        # Populate property hash
        expect{ provider.exists? }.to raise_error(/expired/)
        expect(get_stub).to have_been_requested.at_least_times(1)
      end
    end
  end

end
