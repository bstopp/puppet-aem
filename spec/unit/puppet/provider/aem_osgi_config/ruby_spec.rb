# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:aem_osgi_config).provider(:ruby) do

  let(:bundle_location) do
    'launchpad:resources/install/999/com.bundle.filename.jar'
  end

  let(:resource) do
    Puppet::Type.type(:aem_osgi_config).new(
      name: 'OsgiConfig',
      ensure: :present,
      configuration: {
        'boolean' => false,
        'long' => 123_456_789,
        'string' => 'string'
      },
      handle_missing: :merge,
      home: '/opt/aem',
      password: 'admin',
      timeout: 1,
      username: 'admin'
    )
  end

  let(:bundles_started) do
    data = <<~JSON
      {
        "s" : [100, 75, 25, 0, 0]
      }
    JSON
    data
  end

  let(:bundles_not_started) do
    data = <<~JSON
      {
        "s" : [100, 50, 25, 20, 5]
      }
    JSON
    data
  end

  let(:provider) do
    provider = described_class.new(resource)
    provider
  end

  let(:config_data) do
    data = <<-JSON
      [
        {
          "pid" : "#{resource[:pid] || resource[:name]}",
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

  let(:config_missing) { [] }

  let(:exception) do
    Errno::ECONNREFUSED.new
  end

  describe 'exists?' do

    describe 'aem not running' do
      it 'should generate an error' do
        WebMock.reset!

        envdata = <<~ENVDATA
          PORT=4502
        ENVDATA

        expect(File).to receive(:foreach).with('/opt/aem/crx-quickstart/bin/start-env').and_yield(envdata)

        aem_root = 'http://localhost:4502'

        started_stub = stub_request(
          :get, "#{aem_root}/system/console/bundles.json"
        ).with(
          headers: { 'Authorization' => 'Basic YWRtaW46YWRtaW4=' }
        ).to_return(status: 200, body: bundles_not_started)

        # Populate property hash
        expect { provider.exists? }.to raise_error(/expired/)
        expect(started_stub).to have_been_requested.at_least_times(1)
      end
    end

    shared_examples 'exists_check' do |opts|
      it do

        WebMock.reset!

        opts ||= {}
        opts[:port] ||= 4502
        opts[:pid] ||= resource[:name]

        crline = "CONTEXT_ROOT='#{opts[:context_root]}'" if opts[:context_root]
        envdata = <<~ENVDATA
          PORT=#{opts[:port]}
          #{crline}
        ENVDATA

        expect(File).to receive(:foreach).with('/opt/aem/crx-quickstart/bin/start-env').and_yield(envdata)

        uri_s = "http://localhost:#{opts[:port]}"
        uri_s = "http://localhost:#{opts[:port]}/#{opts[:context_root]}" if opts[:context_root]
        aem_root = uri_s
        uri_s = "#{uri_s}/system/console/configMgr/#{opts[:pid]}.json"
        uri = URI(uri_s)

        body = opts[:present] ? config_data : config_missing

        started_stub = stub_request(
          :get, "#{aem_root}/system/console/bundles.json"
        ).with(
          headers: { 'Authorization' => 'Basic YWRtaW46YWRtaW4=' }
        ).to_return(status: 200, body: bundles_started)

        get_stub = stub_request(
          :get, "#{uri.scheme}://#{uri.host}:#{uri.port}#{uri.path}"
        ).with(
          headers: { 'Authorization' => 'Basic YWRtaW46YWRtaW4=' }
        ).to_return(status: 200, body: body.to_s)

        expect(provider.exists?).to eq(opts[:present])
        expect(started_stub).to have_been_requested
        expect(get_stub).to have_been_requested

        if opts[:present]
          configuration = provider.configuration
          expect(provider.ensure).to eq(:present)
          expect(configuration['boolean']).to eq(false)
          expect(configuration['long']).to eq(123_456_789)
          expect(configuration['string']).to eq('string')
        else
          expect(provider.ensure).to eq(:absent)
        end

      end
    end

    describe 'ensure is absent' do

      it_should_behave_like('exists_check', present: false)
    end

    describe 'ensure is present' do
      it_should_behave_like('exists_check', present: true)
    end

    describe 'ensure is present with context root' do
      it_should_behave_like('exists_check', present: true, context_root: 'contextroot')
    end

    context 'ensure is present with a pid' do
      let(:resource) do
        Puppet::Type.type(:aem_osgi_config).new(
          name: 'OsgiConfig',
          ensure: :present,
          configuration: {
            'boolean' => false,
            'long' => 123_456_789,
            'string' => 'string'
          },
          handle_missing: :merge,
          home: '/opt/aem',
          password: 'admin',
          pid: 'aem.osgi',
          timeout: 1,
          username: 'admin'
        )
      end

      it_should_behave_like('exists_check', present: true, context_root: 'contextroot', pid: 'aem.osgi')
    end
  end

  describe 'flush' do
    shared_examples 'flush_posts' do |opts|
      it do
        WebMock.reset!

        opts ||= {}
        opts[:port] ||= 4502
        opts[:pid] ||= resource[:name]

        crline = "CONTEXT_ROOT='#{opts[:context_root]}'" if opts[:context_root]
        envdata = <<~ENVDATA
          PORT=#{opts[:port]}
          #{crline}
        ENVDATA

        expect(File).to receive(:foreach).with('/opt/aem/crx-quickstart/bin/start-env').and_yield(envdata)

        uri_s = "http://localhost:#{opts[:port]}"
        uri_s = "http://localhost:#{opts[:port]}/#{opts[:context_root]}" if opts[:context_root]
        aem_root = uri_s
        uri_s = "#{uri_s}/system/console/configMgr/#{opts[:pid]}.json"
        uri = URI(uri_s)

        started_stub = stub_request(
          :get, "#{aem_root}/system/console/bundles.json"
        ).with(
          headers: { 'Authorization' => 'Basic YWRtaW46YWRtaW4=' }
        ).to_return(status: 200, body: bundles_started)

        exists_body = opts[:present] ? config_data : config_missing
        updated_body = after_data
        get_stub = stub_request(
          :get, "#{uri.scheme}://#{uri.host}:#{uri.port}#{uri.path}"
        ).with(
          headers: { 'Authorization' => 'Basic YWRtaW46YWRtaW4=' }
        ).to_return(
          { status: 200, body: exists_body.to_s },
          status: 200,
          body: updated_body.to_s
        )

        expected_params = opts[:post_params].merge('apply' => 'true')
        expected_params['$location'] = bundle_location if opts[:present] && !opts[:destroy]

        post_stub = stub_request(
          :post, "http://localhost:4502/system/console/configMgr/#{opts[:pid]}"
        ).with(
          body: expected_params,
          headers: {
            'Referer' => 'http://localhost:4502/system/console/configMgr',
            'Authorization' => 'Basic YWRtaW46YWRtaW4='
          }
        ).to_return(status: 200)

        # Populate property hash
        provider.exists?

        if opts[:destroy]
          provider.destroy
        else
          provider.create
        end

        expect(provider.configuration).not_to eq(resource[:configuration])
        expect { provider.flush }.not_to raise_error
        expect(started_stub).to have_been_requested
        expect(get_stub).to have_been_requested.twice
        expect(post_stub).to have_been_requested
        expect(provider.configuration).to eq(resource[:configuration] || :absent)
      end
    end

    describe 'create' do
      let(:resource) do
        Puppet::Type.type(:aem_osgi_config).new(
          name: 'OsgiConfig',
          ensure: :present,
          configuration: {
            'boolean' => true,
            'long' => 987_654_321,
            'string' => 'string'
          },
          handle_missing: :merge,
          home: '/opt/aem',
          password: 'admin',
          timeout: 5,
          username: 'admin'
        )
      end

      let(:after_data) do
        data = JSON.parse(config_data.dup)
        data[0]['properties'] = {
          'boolean' => {
            'is_set' => true,
            'value' => true
          },
          'long' => {
            'is_set' => true,
            'value' => 987_654_321
          },
          'string' => {
            'is_set' => true,
            'value' => 'string'
          }
        }
        data.to_json
      end

      it_should_behave_like(
        'flush_posts',
        present: false,
        post_params: {
          'propertylist' => 'boolean,long,string',
          'boolean' => 'true',
          'long' => '987654321',
          'string' => 'string'
        }
      )
    end

    describe 'create with pid' do
      let(:resource) do
        Puppet::Type.type(:aem_osgi_config).new(
          name: 'OsgiConfig',
          ensure: :present,
          configuration: {
            'boolean' => true,
            'long' => 987_654_321,
            'string' => 'string'
          },
          handle_missing: :merge,
          home: '/opt/aem',
          password: 'admin',
          pid: 'aem.osgi',
          timeout: 1,
          username: 'admin'
        )
      end

      let(:after_data) do
        data = JSON.parse(config_data.dup)
        data[0]['properties'] = {
          'boolean' => {
            'is_set' => true,
            'value' => true
          },
          'long' => {
            'is_set' => true,
            'value' => 987_654_321
          },
          'string' => {
            'is_set' => true,
            'value' => 'string'
          }
        }
        data.to_json
      end

      it_should_behave_like(
        'flush_posts',
        present: false,
        post_params: {
          'propertylist' => 'boolean,long,string',
          'boolean' => 'true',
          'long' => '987654321',
          'string' => 'string'
        },
        pid: 'aem.osgi'
      )
    end

    describe 'destroy' do
      let(:resource) do
        Puppet::Type.type(:aem_osgi_config).new(
          name: 'OsgiConfig',
          ensure: :absent,
          home: '/opt/aem',
          password: 'admin',
          timeout: 1,
          username: 'admin'
        )
      end
      let(:after_data) { config_missing }
      it_should_behave_like(
        'flush_posts',
        present: true,
        destroy: true,
        post_params: {
          'delete' => 'true'
        }
      )
    end

    describe 'destroy with pid' do
      let(:resource) do
        Puppet::Type.type(:aem_osgi_config).new(
          name: 'OsgiConfig',
          ensure: :absent,
          home: '/opt/aem',
          password: 'admin',
          pid: 'aem.osgi',
          timeout: 1,
          username: 'admin'
        )
      end
      let(:after_data) { config_missing }
      it_should_behave_like(
        'flush_posts',
        present: true,
        destroy: true,
        post_params: {
          'delete' => 'true'
        },
        pid: 'aem.osgi'
      )
    end

    describe 'update with remove' do
      let(:resource) do
        Puppet::Type.type(:aem_osgi_config).new(
          name: 'OsgiConfig',
          ensure: :present,
          configuration: {
            'boolean' => true,
            'long' => 987_654_321
          },
          handle_missing: :remove,
          home: '/opt/aem',
          password: 'admin',
          timeout: 1,
          username: 'admin'
        )
      end
      let(:after_data) do
        data = JSON.parse(config_data.dup)
        data[0]['properties'] = {
          'boolean' => {
            'is_set' => true,
            'value' => true
          },
          'long' => {
            'is_set' => true,
            'value' => 987_654_321
          }
        }
        data.to_json
      end
      it_should_behave_like(
        'flush_posts',
        present: true,
        post_params: {
          'propertylist' => 'boolean,long',
          'boolean' => 'true',
          'long' => '987654321'
        }
      )
    end

    describe 'update with remove using pid' do
      let(:resource) do
        Puppet::Type.type(:aem_osgi_config).new(
          name: 'OsgiConfig',
          ensure: :present,
          configuration: {
            'boolean' => true,
            'long' => 987_654_321
          },
          handle_missing: :remove,
          home: '/opt/aem',
          password: 'admin',
          pid: 'aem.osgi',
          timeout: 1,
          username: 'admin'
        )
      end
      let(:after_data) do
        data = JSON.parse(config_data.dup)
        data[0]['properties'] = {
          'boolean' => {
            'is_set' => true,
            'value' => true
          },
          'long' => {
            'is_set' => true,
            'value' => 987_654_321
          }
        }
        data.to_json
      end
      it_should_behave_like(
        'flush_posts',
        present: true,
        post_params: {
          'propertylist' => 'boolean,long',
          'boolean' => 'true',
          'long' => '987654321'
        },
        pid: 'aem.osgi'
      )
    end

    describe 'update with merge' do
      let(:resource) do
        Puppet::Type.type(:aem_osgi_config).new(
          name: 'OsgiConfig',
          ensure: :present,
          configuration: {
            'long' => 987_654_321
          },
          handle_missing: :merge,
          home: '/opt/aem',
          password: 'admin',
          timeout: 1,
          username: 'admin'
        )
      end
      let(:after_data) do
        data = JSON.parse(config_data.dup)
        data[0]['properties'] = {
          'long' => {
            'is_set' => true,
            'value' => 987_654_321
          }
        }
        data.to_json
      end
      it_should_behave_like(
        'flush_posts',
        present: true,
        post_params: {
          'propertylist' => 'boolean,long,string',
          'boolean' => 'false',
          'long' => '987654321',
          'string' => 'string'
        }
      )
    end

    describe 'update with merge using pid' do
      let(:resource) do
        Puppet::Type.type(:aem_osgi_config).new(
          name: 'OsgiConfig',
          ensure: :present,
          configuration: {
            'long' => 987_654_321
          },
          handle_missing: :merge,
          home: '/opt/aem',
          password: 'admin',
          pid: 'aem.osgi',
          timeout: 1,
          username: 'admin'
        )
      end
      let(:after_data) do
        data = JSON.parse(config_data.dup)
        data[0]['properties'] = {
          'long' => {
            'is_set' => true,
            'value' => 987_654_321
          }
        }
        data.to_json
      end

      it_should_behave_like(
        'flush_posts',
        present: true,
        post_params: {
          'propertylist' => 'boolean,long,string',
          'boolean' => 'false',
          'long' => '987654321',
          'string' => 'string'
        },
        pid: 'aem.osgi'
      )
    end

    describe 'create with array because webmock has issues matching array in a hash for parameters' do
      let(:resource) do
        Puppet::Type.type(:aem_osgi_config).new(
          name: 'OsgiConfig',
          ensure: :present,
          configuration: {
            'boolean' => false,
            'long' => 123_456_789,
            'string' => 'string',
            'array' => %w[this is an array]
          },
          handle_missing: :merge,
          home: '/opt/aem',
          password: 'admin',
          timeout: 1,
          username: 'admin'
        )
      end

      let(:after_data) do
        data = JSON.parse(config_data.dup)
        data[0]['properties'] = {
          'boolean' => {
            'is_set' => true,
            'value' => false
          },
          'long' => {
            'is_set' => true,
            'value' => 123_456_789
          },
          'string' => {
            'is_set' => true,
            'value' => 'string'
          },
          'array' => {
            'is_set' => true,
            'value' => %w[this is an array]
          }
        }
        data.to_json
      end

      it 'should work without errors' do
        WebMock.reset!

        envdata = <<~ENVDATA
          PORT=4502
        ENVDATA

        expect(File).to receive(:foreach).with('/opt/aem/crx-quickstart/bin/start-env').and_yield(envdata)

        aem_root = 'http://localhost:4502'
        uri_s = "#{aem_root}/system/console/configMgr/#{resource[:name]}.json"
        uri = URI(uri_s)

        started_stub = stub_request(
          :get, "#{aem_root}/system/console/bundles.json"
        ).with(
          headers: { 'Authorization' => 'Basic YWRtaW46YWRtaW4=' }
        ).to_return(status: 200, body: bundles_started)

        get_stub = stub_request(
          :get, "#{uri.scheme}://#{uri.host}:#{uri.port}#{uri.path}"
        ).with(
          headers: { 'Authorization' => 'Basic YWRtaW46YWRtaW4=' }
        ).to_return(
          { status: 200, body: config_missing.to_s },
          status: 200,
          body: after_data.to_s
        )

        expected_params = 'boolean=false&long=123456789&string=string&array=this&array=is&array=an&array=array'
        expected_params += '&propertylist=boolean%2Clong%2Cstring%2Carray&apply=true'

        post_stub = stub_request(
          :post, 'http://localhost:4502/system/console/configMgr/OsgiConfig'
        ).with(
          body: expected_params,
          headers: {
            'Referer' => 'http://localhost:4502/system/console/configMgr',
            'Authorization' => 'Basic YWRtaW46YWRtaW4='
          }
        ).to_return(status: 200)

        # Populate property hash
        provider.exists?
        provider.create
        expect(provider.configuration).not_to eq(resource[:configuration])
        expect { provider.flush }.not_to raise_error
        expect(started_stub).to have_been_requested
        expect(get_stub).to have_been_requested.twice
        expect(post_stub).to have_been_requested
        expect(provider.configuration).to eq(resource[:configuration])

      end
    end

    describe 'flush post errors' do
      it 'should generate an error' do
        WebMock.reset!

        envdata = <<~ENVDATA
          PORT=4502
        ENVDATA

        expect(File).to receive(:foreach).with('/opt/aem/crx-quickstart/bin/start-env').and_yield(envdata)

        aem_root = 'http://localhost:4502'
        uri_s = "#{aem_root}/system/console/configMgr/#{resource[:name]}.json"
        uri = URI(uri_s)

        started_stub = stub_request(
          :get, "#{aem_root}/system/console/bundles.json"
        ).with(
          headers: { 'Authorization' => 'Basic YWRtaW46YWRtaW4=' }
        ).to_return(status: 200, body: bundles_started)

        get_stub = stub_request(
          :get, "#{uri.scheme}://#{uri.host}:#{uri.port}#{uri.path}"
        ).to_return(status: 200, body: config_data)

        post_stub = stub_request(
          :post, 'http://localhost:4502/system/console/configMgr/OsgiConfig'
        ).with(
          body: {
            'delete' => 'true',
            'apply' => 'true'
          },
          headers: { 'Authorization' => 'Basic YWRtaW46YWRtaW4=' }
        ).to_return(status: 500)

        # Populate property hash
        provider.exists?
        provider.destroy
        expect { provider.flush }.to raise_error(/500/)
        expect(started_stub).to have_been_requested
        expect(get_stub).to have_been_requested.once
        expect(post_stub).to have_been_requested
      end
    end
  end
end
