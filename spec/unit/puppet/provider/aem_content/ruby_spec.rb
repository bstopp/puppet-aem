require 'spec_helper'

describe Puppet::Type.type(:aem_content).provider(:ruby) do

  let(:resource) do
    Puppet::Type.type(:aem_content).new(
      :name       => '/etc/testcontent/nodename',
      :ensure     => :present,
      :properties => {
        'title' => 'string',
        'text'  => 'string with text',
      },
      :home       => '/opt/aem',
      :password   => 'admin',
      :username   => 'admin',
      :timeout    => 1,
    )
  end

  let(:provider) do
    provider = described_class.new(resource)
    provider
  end

  before do
    @provider_class = described_class
    @provider_class.stubs(:suitable?).returns true
    Puppet::Type.type(:aem_content).stubs(:defaultprovider).returns @provider_class
  end

  describe 'exists?' do

    shared_examples 'exists_check' do |opts|
      it do
        WebMock.reset!

        opts ||= {}
        opts[:port] ||= 4502
        opts[:name] ||= resource[:name]

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
        uri_s = "#{uri_s}#{opts[:name]}"
        uri = URI(uri_s)

        status = opts[:present] ? 302 : 404

        get_stub = stub_request(
          :head, "#{uri.scheme}://admin:admin@#{uri.host}:#{uri.port}#{uri.path}"
        ).to_return(:status => status)

        expect(provider.exists?).to eq(opts[:present])
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
        opts[:name] ||= resource[:name]

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
        uri_s = "#{uri_s}#{opts[:name]}"
        uri = URI(uri_s)

        status = opts[:present] ? 302 : 404

        head_stub = stub_request(
          :head, "#{uri.scheme}://admin:admin@#{uri.host}:#{uri.port}#{uri.path}"
        ).to_return(:status => status)

        expected_params = opts[:post_params]
        #expected_params = {"text"=>"string", "title"=>"string"}
        #expected_params = 'title=string&text=string'

        post_stub = stub_request(
          :post, "#{uri.scheme}://admin:admin@#{uri.host}:#{uri.port}#{uri.path}"
        ).with(
          :body => expected_params,
          :headers => {'Accept'=>'*/*', 'Content-Type'=>'application/x-www-form-urlencoded', 'Referer'=>"#{uri.scheme}://#{uri.host}:#{uri.port}#{uri.path}", 'User-Agent'=>'Ruby'}
        ).to_return(:status => 200, :body => "", :headers => {})

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
        expect(head_stub).to have_been_requested.times(times)
        expect(post_stub).to have_been_requested
      end
    end

    describe 'create' do
      let(:resource) do
        Puppet::Type.type(:aem_content).new(
          :name       => '/etc/testcontent/nodename',
          :ensure     => :present,
          :properties => {
            'title' => 'string',
            'text'  => 'string',
          },
          :home       => '/opt/aem',
          :password   => 'admin',
          :username   => 'admin'
        )
      end

      it_should_behave_like 'flush_posts',
        :present => false,
        :post_params => {
          'title' => 'string',
          'text'  => 'string',
        }
    end
  end

end
