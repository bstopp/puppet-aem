require 'spec_helper'

describe Puppet::Type.type(:aem_sling_resource).provider(:ruby) do

  let(:resource) do
    Puppet::Type.type(:aem_sling_resource).new(
      :name       => '/etc/testcontent/nodename',
      :ensure     => :present,
      :properties => {
        'title' => 'string',
        'text'  => 'string with text',
      },
      :home       => '/opt/aem',
      :password   => 'admin',
      :username   => 'admin',
      :timeout    => 1
    )
  end

  let(:provider) do
    provider = described_class.new(resource)
    provider
  end

  let(:content_data) do
    data = <<-JSON
      {
        "jcr:primaryType" : "cq:Page",
        "jcr:content": {
          "jcr:primaryType": "nt:unstructured",
          "jcr:title": "Default Agent",
          "enabled": "false",
          "transportUri": "http://host:port/bin/receive?sling:authRequestLogin=1",
          "transportUser": "replication-receiver",
          "cq:template": "/libs/cq/replication/templates/agent",
          "serializationType": "durbo",
          "retryDelay": "60000",
          "userId": "your_replication_user",
          "jcr:description": "Agent that replicates to the default publish instance.",
          "sling:resourceType": "cq/replication/components/agent",
          "transportPassword": "",
          "logLevel": "info"
        }
      }
    JSON
    data
  end

  describe 'exists?' do

    shared_examples 'exists_check' do |opts|
      it do

        WebMock.reset!

        opts ||= {}
        opts[:port] ||= 4502
        opts[:path] ||= resource[:name]
        opts[:depth] ||= 0

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
        uri_s = "#{uri_s}#{opts[:path]}"
        uri = URI(uri_s)

        status = opts[:present] ? 200 : 404

        get_stub = stub_request(
          :get, "#{uri.scheme}://admin:admin@#{uri.host}:#{uri.port}#{uri.path}.#{opts[:depth]}.json"
        ).to_return(:status => status, :body => content_data)

        expect(provider.exists?).to eq(opts[:present])
        expect(get_stub).to have_been_requested

        if opts[:present]
          res_data = provider.properties
          expect(res_data).to_not eq(:absent)
          expect(res_data['jcr:primaryType']).to eq('cq:Page')
          expect(res_data['jcr:content']).to be_a(Hash)
          expect(res_data['jcr:content']['jcr:primaryType']).to eq('nt:unstructured')
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

    describe 'ensure check timesout' do
      it 'should generate an error' do
        WebMock.reset!
        envdata = <<-EOF
PORT=4502
        EOF

        expect(File).to receive(:foreach).with('/opt/aem/crx-quickstart/bin/start-env').and_yield(envdata)

        uri_s = "http://localhost:4502#{resource[:name]}"
        uri = URI(uri_s)

        get_stub = stub_request(
          :get, "#{uri.scheme}://admin:admin@#{uri.host}:#{uri.port}#{uri.path}.0.json"
        ).to_timeout

        expect{ provider.exists? }.to raise_error(/expired/)
        expect(get_stub).to have_been_requested.at_least_times(1)
      end
    end
  end

  describe 'flush' do
    shared_examples 'flush_posts' do |opts|
      it do

        WebMock.reset!

        opts ||= {}
        opts[:port] ||= 4502
        opts[:path] ||= resource[:name]
        opts[:depth] ||= 0

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
        uri_s = "#{uri_s}#{opts[:path]}"
        uri = URI(uri_s)

        status = opts[:present] ? 200 : 404

        get_stub = stub_request(
          :get, "#{uri.scheme}://admin:admin@#{uri.host}:#{uri.port}#{uri.path}.#{opts[:depth]}.json"
        ).to_return(:status => status, :body => content_data)

        expected_params = opts[:form_params]

        post_stub = stub_request(
          :post, "#{uri.scheme}://admin:admin@#{uri.host}:#{uri.port}#{uri.path}"
        ).with(
          :body => expected_params,
          :headers => { 'Referer' => "#{uri.scheme}://#{uri.host}:#{uri.port}#{uri.path}" }
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
      
    end

    describe 'create with path' do
      
    end

    describe 'destroy' do
      let(:resource) do
        Puppet::Type.type(:aem_sling_resource).new(
          :name           => '/etc/testcontent/nodename',
          :ensure         => :absent,
          :home           => '/opt/aem',
          :password       => 'admin',
          :username       => 'admin',
          :properties     => {
            'title' => 'string',
            'text'  => 'string',
          }
        )
      end
      
      it_should_behave_like 'flush_posts',
        :present => false,
        :destroy => true,
        :form_params => { ':operation' => 'delete' }
    end

    describe 'destroy with path' do
      
    end

    describe 'update with remove' do
      
    end

    describe 'update with remove with nested hash' do
      
    end

    describe 'update with remove using path' do
      
    end

    describe 'update with merge' do
      
    end

    describe 'update with merge with nested hash' do
      
    end

    describe 'update with merge using path' do
      
    end

    describe 'update with ignore' do
      
    end

    describe 'update with ignore with nested hash' do
      
    end

    describe 'update with ignore using path' do
      
    end

    describe 'create with array because webmock has issues matching array in a hash for parameters' do
      
    end

    describe 'flush post errors' do
      it 'should generate an error' do
        WebMock.reset!

        envdata = <<-EOF
PORT=4502
        EOF

        expect(File).to receive(:foreach).with('/opt/aem/crx-quickstart/bin/start-env').and_yield(envdata)

        uri_s = 'http://localhost:4502/etc/testcontent/nodename.0.json'
        uri = URI(uri_s)

        get_stub = stub_request(
          :get, "#{uri.scheme}://admin:admin@#{uri.host}:#{uri.port}#{uri.path}"
        ).to_return(:status => 200, :body => content_data)

        post_stub = stub_request(
          :post, 'http://admin:admin@localhost:4502/etc/testcontent/nodename'
        ).with(
            :body =>  { ':operation' => 'delete' }
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

        uri_s = 'http://localhost:4502/etc/testcontent/nodename.0.json'
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
