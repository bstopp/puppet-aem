require 'spec_helper'

describe Puppet::Type.type(:aem_sling_resource).provider(:ruby) do

  let(:resource) do
    Puppet::Type.type(:aem_sling_resource).new(
      :name       => '/etc/testcontent/nodename',
      :ensure     => :present,
      :properties => {
        'title' => 'string',
        'text'  => 'string with text'
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
        "title" : "Page Title",
        "apassword" : "password",
        "jcr:content": {
          "jcr:primaryType": "nt:unstructured",
          "jcr:title": "Default Agent",
          "anotherpassword" : "password",
          "par" : {
            "jcr:primaryType" : "nt:unstructured",
            "property" : "prop value",
            "onemorepassword" : "password"
          }
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
        opts[:depth] ||= 1

        crline = "CONTEXT_ROOT='#{opts[:context_root]}'" if opts[:context_root]
        envdata = <<-EOF
PORT=#{opts[:port]}
#{crline}
        EOF

        expect(File).to receive(:foreach).with('/opt/aem/crx-quickstart/bin/start-env').and_yield(envdata)

        uri_s = "http://localhost:#{opts[:port]}"
        uri_s = "http://localhost:#{opts[:port]}/#{opts[:context_root]}" if opts[:context_root]
        uri_s = "#{uri_s}#{opts[:path]}"
        uri = URI(uri_s)

        status = opts[:present] ? 200 : 404

        get_stub = stub_request(
          :get, "#{uri.scheme}://#{uri.host}:#{uri.port}#{uri.path}.#{opts[:depth]}.json"
        ).with(
          :headers => { 'Authorization' => 'Basic YWRtaW46YWRtaW4=' }
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
      it_should_behave_like('exists_check', :present => false)
    end

    describe 'ensure is present' do
      it_should_behave_like('exists_check', :present => true)
    end

    describe 'ensure is present with context root' do
      it_should_behave_like('exists_check', :present => true, :context_root => 'contextroot')
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
          :get, "#{uri.scheme}://#{uri.host}:#{uri.port}#{uri.path}.1.json"
        ).with(
          :headers => { 'Authorization' => 'Basic YWRtaW46YWRtaW4=' }
        ).to_timeout

        expect { provider.exists? }.to raise_error(/expired/)
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
        opts[:depth] ||= 1

        crline = "CONTEXT_ROOT='#{opts[:context_root]}'" if opts[:context_root]
        envdata = <<-EOF
PORT=#{opts[:port]}
#{crline}
        EOF

        expect(File).to receive(:foreach).with('/opt/aem/crx-quickstart/bin/start-env').and_yield(envdata)

        uri_s = "http://localhost:#{opts[:port]}"
        uri_s = "http://localhost:#{opts[:port]}/#{opts[:context_root]}" if opts[:context_root]
        uri_s = "#{uri_s}#{opts[:path]}"
        uri = URI(uri_s)

        status = opts[:present] ? 200 : 404

        get_stub = stub_request(
          :get, "#{uri.scheme}://#{uri.host}:#{uri.port}#{uri.path}.#{opts[:depth]}.json"
        ).with(
          :headers => { 'Authorization' => 'Basic YWRtaW46YWRtaW4=' }
        ).to_return(:status => status, :body => content_data)

        expected_params = opts[:form_params]

        post_stub = stub_request(
          :post, "#{uri.scheme}://#{uri.host}:#{uri.port}#{uri.path}"
        ).with(
          :body => expected_params,
          :headers => {
            'Referer' => "#{uri.scheme}://#{uri.host}:#{uri.port}#{uri.path}",
            'Authorization' => 'Basic YWRtaW46YWRtaW4='
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

        expect { provider.flush }.to_not raise_error
        expect(get_stub).to have_been_requested.times(times)
        expect(post_stub).to have_been_requested
      end
    end

    describe 'create' do
      describe 'base' do
        let(:resource) do
          Puppet::Type.type(:aem_sling_resource).new(
            :name       => '/etc/testcontent/nodename',
            :ensure     => :present,
            :home       => '/opt/aem',
            :password   => 'admin',
            :username   => 'admin',
            :properties => {
              'title'           => 'title string',
              'text'            => 'text string'
            }
          )
        end

        params = {
          'title' => 'title string',
          'text' => 'text string'
        }

        it_should_behave_like(
          'flush_posts',
          :present => false,
          :form_params => params
        )
      end

      describe 'with path' do
        let(:resource) do
          Puppet::Type.type(:aem_sling_resource).new(
            :name       => 'A resource name',
            :ensure     => :present,
            :home       => '/opt/aem',
            :path       => '/path/to/resource',
            :password   => 'admin',
            :username   => 'admin',
            :properties => {
              'title' => 'title string',
              'text'  => 'text string'
            }
          )
        end

        params = 'title=title+string'
        params += '&text=text+string'

        it_should_behave_like(
          'flush_posts',
          :path => '/path/to/resource',
          :present => false,
          :form_params => params
        )
      end

      describe 'with array property' do
        let(:resource) do
          Puppet::Type.type(:aem_sling_resource).new(
            :name       => 'A resource name',
            :ensure     => :present,
            :home       => '/opt/aem',
            :path       => '/path/to/resource',
            :password   => 'admin',
            :username   => 'admin',
            :properties => {
              'title' => 'title string',
              'text'  => 'text string',
              'array' => ['this', 'is', 'an', 'array']
            }
          )
        end

        params = 'title=title+string'
        params += '&text=text+string'
        params += '&array=this'
        params += '&array=is'
        params += '&array=an'
        params += '&array=array'

        it_should_behave_like(
          'flush_posts',
          :path => '/path/to/resource',
          :present => false,
          :form_params => params
        )
      end

      describe 'with nested hash' do
        let(:resource) do
          Puppet::Type.type(:aem_sling_resource).new(
            :name       => '/path/to/resource',
            :ensure     => :present,
            :home       => '/opt/aem',
            :password   => 'admin',
            :username   => 'admin',
            :properties => {
              'title' => 'title string',
              'text'  => 'text string',
              'subnode' => {
                'property' => 'value'
              }
            }
          )
        end

        params = 'title=title+string'
        params += '&text=text+string'
        params += '&subnode%2Fproperty=value'

        it_should_behave_like(
          'flush_posts',
          :depth => 2,
          :path => '/path/to/resource',
          :present => false,
          :form_params => params
        )
      end

      describe 'with tiered nested hash' do
        let(:resource) do
          Puppet::Type.type(:aem_sling_resource).new(
            :name       => '/path/to/resource',
            :ensure     => :present,
            :home       => '/opt/aem',
            :password   => 'admin',
            :username   => 'admin',
            :properties => {
              'title' => 'title string',
              'text'  => 'text string',
              'child' => {
                'property' => 'value',
                'grandchild' => {
                  'child attrib' => 'another value',
                  'array' => ['this', 'is', 'an', 'array']
                }
              }
            }
          )
        end

        params = 'title=title+string'
        params += '&text=text+string&child%2Fproperty=value'
        params += '&child%2Fgrandchild%2Fchild+attrib=another+value'
        params += '&child%2Fgrandchild%2Farray=this'
        params += '&child%2Fgrandchild%2Farray=is'
        params += '&child%2Fgrandchild%2Farray=an'
        params += '&child%2Fgrandchild%2Farray=array'

        it_should_behave_like(
          'flush_posts',
          :depth => 3,
          :path => '/path/to/resource',
          :present => false,
          :form_params => params
        )
      end

      describe 'with tiered nested hash including protected properties' do
        let(:resource) do
          Puppet::Type.type(:aem_sling_resource).new(
            :name       => '/path/to/resource',
            :ensure     => :present,
            :home       => '/opt/aem',
            :password   => 'admin',
            :username   => 'admin',
            :properties => {
              'jcr:primaryType' => 'cq:Page',
              'title'           => 'title string',
              'text'            => 'text string',
              'child'           => {
                'jcr:primaryType' => 'cq:PageContent',
                'property'        => 'value',
                'grandchild'      => {
                  'jcr:primaryType' => 'nt:unstructured',
                  'child attrib'    => 'another value',
                  'array'           => ['this', 'is', 'an', 'array']
                }
              }
            }
          )
        end

        params = 'jcr%3AprimaryType=cq%3APage'
        params += '&title=title+string'
        params += '&text=text+string'
        params += '&child%2Fjcr%3AprimaryType=cq%3APageContent'
        params += '&child%2Fproperty=value'
        params += '&child%2Fgrandchild%2Fjcr%3AprimaryType=nt%3Aunstructured'
        params += '&child%2Fgrandchild%2Fchild+attrib=another+value'
        params += '&child%2Fgrandchild%2Farray=this'
        params += '&child%2Fgrandchild%2Farray=is'
        params += '&child%2Fgrandchild%2Farray=an'
        params += '&child%2Fgrandchild%2Farray=array'

        it_should_behave_like(
          'flush_posts',
          :depth => 3,
          :path => '/path/to/resource',
          :present => false,
          :form_params => params
        )
      end

      describe 'with tiered nested hash passwords' do
        let(:resource) do
          Puppet::Type.type(:aem_sling_resource).new(
            :name                => '/path/to/resource',
            :ensure              => :present,
            :home                => '/opt/aem',
            :password            => 'admin',
            :password_properties => ['apassword', 'anotherpassword', 'onemorepassword'],
            :username            => 'admin',
            :properties          => {
              'title'     => 'title string',
              'text'      => 'text string',
              'apassword' => 'password',
              'child'     => {
                'property'        => 'value',
                'anotherpassword' => 'password',
                'grandchild' => {
                  'child attrib'    => 'another value',
                  'onemorepassword' => 'password',
                  'array' => ['this', 'is', 'an', 'array']
                }
              }
            }
          )
        end

        params = 'title=title+string'
        params += '&text=text+string'
        params += '&apassword=password'
        params += '&child%2Fproperty=value'
        params += '&child%2Fanotherpassword=password'
        params += '&child%2Fgrandchild%2Fchild+attrib=another+value'
        params += '&child%2Fgrandchild%2Fonemorepassword=password'
        params += '&child%2Fgrandchild%2Farray=this'
        params += '&child%2Fgrandchild%2Farray=is'
        params += '&child%2Fgrandchild%2Farray=an'
        params += '&child%2Fgrandchild%2Farray=array'

        it_should_behave_like(
          'flush_posts',
          :depth => 3,
          :path => '/path/to/resource',
          :present => false,
          :form_params => params
        )
      end
    end

    describe 'destroy' do
      describe 'default' do
        let(:resource) do
          Puppet::Type.type(:aem_sling_resource).new(
            :name       => '/etc/testcontent/nodename',
            :ensure     => :absent,
            :home       => '/opt/aem',
            :password   => 'admin',
            :username   => 'admin',
            :properties => {
              'title' => 'string',
              'text'  => 'string'
            }
          )
        end

        it_should_behave_like(
          'flush_posts',
          :destroy => true,
          :form_params => { ':operation' => 'delete' }
        )
      end

      describe 'with path' do
        let(:resource) do
          Puppet::Type.type(:aem_sling_resource).new(
            :name       => 'This is a node name',
            :ensure     => :absent,
            :home       => '/opt/aem',
            :password   => 'admin',
            :path       => '/new/path/to/node',
            :username   => 'admin',
            :properties => {
              'title' => 'string',
              'text'  => 'string'
            }
          )
        end

        it_should_behave_like(
          'flush_posts',
          :destroy => true,
          :path => '/new/path/to/node',
          :form_params => { ':operation' => 'delete' }
        )
      end
    end

    describe 'update' do
      describe 'remove' do
        describe 'default' do
          let(:resource) do
            Puppet::Type.type(:aem_sling_resource).new(
              :name                => '/path/to/resource',
              :ensure              => :present,
              :handle_missing      => :remove,
              :home                => '/opt/aem',
              :password            => 'admin',
              :password_properties => ['apassword', 'anotherpassword', 'onemorepassword'],
              :username            => 'admin',
              :properties          => {
                'jcr:primaryType' => 'nt:unstructured',
                'jcr:title'       => 'A new title'
              }
            )
          end

          params = {
            'title@Delete'       => '',
            'jcr:content@Delete' => '',
            'jcr:title'          => 'A new title'
          }

          it_should_behave_like(
            'flush_posts',
            :path => '/path/to/resource',
            :present => true,
            :form_params => params
          )
        end

        describe 'nested hash' do
          let(:resource) do
            Puppet::Type.type(:aem_sling_resource).new(
              :name                => '/path/to/resource',
              :ensure              => :present,
              :handle_missing      => :remove,
              :home                => '/opt/aem',
              :password            => 'admin',
              :password_properties => ['apassword', 'anotherpassword', 'onemorepassword'],
              :username            => 'admin',
              :properties          => {
                'jcr:primaryType' => 'nt:unstructured',
                'title'           => 'Page Title',
                'jcr:content'     => {
                  'title' => 'new title property'
                }
              }
            )
          end

          params = {
            'title'                              => 'Page Title',
            'jcr:content/jcr:title@Delete'       => '',
            'jcr:content/title'                  => 'new title property',
            'jcr:content/par@Delete'             => ''
          }

          it_should_behave_like(
            'flush_posts',
            :depth => 2,
            :path => '/path/to/resource',
            :present => true,
            :form_params => params
          )
        end

        describe 'tiered nested hash' do
          let(:resource) do
            Puppet::Type.type(:aem_sling_resource).new(
              :name                => '/path/to/resource',
              :ensure              => :present,
              :handle_missing      => :remove,
              :home                => '/opt/aem',
              :password            => 'admin',
              :password_properties => ['apassword', 'anotherpassword', 'onemorepassword'],
              :username            => 'admin',
              :properties          => {
                'jcr:primaryType' => 'nt:unstructured',
                'title'           => 'Page Title',
                'jcr:content' => {
                  'title' => 'new title property',
                  'par'   => {
                    'newprop' => 'new prop value'
                  }
                }
              }
            )
          end

          params = {
            'title'                                  => 'Page Title',
            'jcr:content/jcr:title@Delete'           => '',
            'jcr:content/title'                      => 'new title property',
            'jcr:content/par/property@Delete'        => '',
            'jcr:content/par/newprop'                => 'new prop value'
          }

          it_should_behave_like(
            'flush_posts',
            :depth => 3,
            :path => '/path/to/resource',
            :present => true,
            :form_params => params
          )
        end

        describe 'property replacing a node' do
          let(:resource) do
            Puppet::Type.type(:aem_sling_resource).new(
              :name                => '/path/to/resource',
              :ensure              => :present,
              :handle_missing      => :remove,
              :home                => '/opt/aem',
              :password            => 'admin',
              :password_properties => ['apassword', 'anotherpassword', 'onemorepassword'],
              :username            => 'admin',
              :properties          => {
                'jcr:primaryType' => 'nt:unstructured',
                'title'           => 'Page Title',
                'jcr:content' => {
                  'title' => 'new title property',
                  'par'   => 'new prop value'
                }
              }
            )
          end

          params = {
            'title'                              => 'Page Title',
            'jcr:content/jcr:title@Delete'       => '',
            'jcr:content/title'                  => 'new title property',
            'jcr:content/par@Delete'             => '',
            'jcr:content/par'                    => 'new prop value'
          }

          it_should_behave_like(
            'flush_posts',
            :depth => 2,
            :path => '/path/to/resource',
            :present => true,
            :form_params => params
          )
        end

        describe 'node replacing a property' do
          let(:resource) do
            Puppet::Type.type(:aem_sling_resource).new(
              :name                => '/path/to/resource',
              :ensure              => :present,
              :handle_missing      => :remove,
              :home                => '/opt/aem',
              :password            => 'admin',
              :password_properties => ['apassword', 'anotherpassword', 'onemorepassword'],
              :username            => 'admin',
              :properties          => {
                'jcr:primaryType' => 'nt:unstructured',
                'title'           => 'Page Title',
                'jcr:content' => {
                  'jcr:title' => 'Default Agent',
                  'par' => {
                    'property' => {
                      'newnode' => 'new prop value'
                    }
                  }
                }
              }
            )
          end

          params = {
            'title'                                  => 'Page Title',
            'jcr:content/jcr:title'                  => 'Default Agent',
            'jcr:content/par/property@Delete'        => '',
            'jcr:content/par/property/newnode'       => 'new prop value'
          }

          it_should_behave_like(
            'flush_posts',
            :depth => 4,
            :path => '/path/to/resource',
            :present => true,
            :form_params => params
          )
        end

        describe 'passwords not forced' do
          let(:resource) do
            Puppet::Type.type(:aem_sling_resource).new(
              :name                => '/path/to/resource',
              :ensure              => :present,
              :handle_missing      => :remove,
              :home                => '/opt/aem',
              :password            => 'admin',
              :password_properties => ['apassword', 'anotherpassword', 'onemorepassword'],
              :username            => 'admin',
              :properties          => {
                'jcr:primaryType' => 'nt:unstructured',
                'title'           => 'Page Title',
                'apassword'       => 'newvalue',
                'jcr:content'     => {
                  'jcr:title'       => 'Default Agent',
                  'anotherpassword' => 'newvale',
                  'par' => {
                    'property'        => 'new prop value',
                    'onemorepassword' => 'newvalue'
                  }
                }
              }
            )
          end

          params = {
            'title'                                  => 'Page Title',
            'jcr:content/jcr:title'                  => 'Default Agent',
            'jcr:content/par/property'               => 'new prop value'
          }

          it_should_behave_like(
            'flush_posts',
            :depth => 3,
            :path => '/path/to/resource',
            :present => true,
            :form_params => params
          )
        end

        describe 'passwords forced' do
          let(:resource) do
            Puppet::Type.type(:aem_sling_resource).new(
              :name                => '/path/to/resource',
              :ensure              => :present,
              :force_passwords     => :true,
              :handle_missing      => :remove,
              :home                => '/opt/aem',
              :password            => 'admin',
              :password_properties => ['apassword', 'anotherpassword', 'onemorepassword'],
              :username            => 'admin',
              :properties          => {
                'jcr:primaryType' => 'nt:unstructured',
                'title'           => 'Page Title',
                'apassword'       => 'newvalue',
                'jcr:content'     => {
                  'jcr:title'       => 'Default Agent',
                  'anotherpassword' => 'newvalue',
                  'par'             => {
                    'property'        => 'new prop value',
                    'onemorepassword' => 'newvalue'
                  }
                }
              }
            )
          end

          params = {
            'title'                                  => 'Page Title',
            'apassword'                              => 'newvalue',
            'jcr:content/jcr:title'                  => 'Default Agent',
            'jcr:content/anotherpassword'            => 'newvalue',
            'jcr:content/par/property'               => 'new prop value',
            'jcr:content/par/onemorepassword'        => 'newvalue'
          }

          it_should_behave_like(
            'flush_posts',
            :depth => 3,
            :path => '/path/to/resource',
            :present => true,
            :form_params => params
          )
        end

        describe 'passwords forced and removed' do
          let(:resource) do
            Puppet::Type.type(:aem_sling_resource).new(
              :name                => '/path/to/resource',
              :ensure              => :present,
              :force_passwords     => :true,
              :handle_missing      => :remove,
              :home                => '/opt/aem',
              :password            => 'admin',
              :password_properties => ['apassword', 'anotherpassword', 'onemorepassword'],
              :username            => 'admin',
              :properties          => {
                'jcr:primaryType' => 'nt:unstructured',
                'title'           => 'Page Title',
                'jcr:content'     => {
                  'jcr:title' => 'Default Agent',
                  'par'       => {
                    'property' => 'new prop value'
                  }
                }
              }
            )
          end

          params = {
            'title'                                  => 'Page Title',
            'apassword@Delete'                       => '',
            'jcr:content/jcr:title'                  => 'Default Agent',
            'jcr:content/anotherpassword@Delete'     => '',
            'jcr:content/par/property'               => 'new prop value',
            'jcr:content/par/onemorepassword@Delete' => ''
          }

          it_should_behave_like(
            'flush_posts',
            :depth => 3,
            :path => '/path/to/resource',
            :present => true,
            :form_params => params
          )
        end

        describe 'using path' do
          let(:resource) do
            Puppet::Type.type(:aem_sling_resource).new(
              :name                => '/path/to/resource',
              :ensure              => :present,
              :handle_missing      => :remove,
              :home                => '/opt/aem',
              :password            => 'admin',
              :password_properties => ['apassword', 'anotherpassword', 'onemorepassword'],
              :username            => 'admin',
              :properties          => {
                'jcr:primaryType' => 'nt:unstructured',
                'jcr:title'       => 'A new title'
              }
            )
          end

          params = {
            'title@Delete'       => '',
            'jcr:title'          => 'A new title',
            'jcr:content@Delete' => ''
          }

          it_should_behave_like(
            'flush_posts',
            :path => '/path/to/resource',
            :present => true,
            :form_params => params
          )
        end
      end

      describe 'ignore' do
        describe 'default' do
          let(:resource) do
            Puppet::Type.type(:aem_sling_resource).new(
              :name       => '/path/to/resource',
              :ensure     => :present,
              :home       => '/opt/aem',
              :password   => 'admin',
              :username   => 'admin',
              :properties => {
                'jcr:title' => 'new title'
              }
            )
          end

          params = 'jcr%3Atitle=new+title'

          it_should_behave_like(
            'flush_posts',
            :path => '/path/to/resource',
            :present => true,
            :form_params => params
          )
        end

        describe 'protected/ignored properties' do
          let(:resource) do
            Puppet::Type.type(:aem_sling_resource).new(
              :name       => '/path/to/resource',
              :ensure     => :present,
              :home       => '/opt/aem',
              :password   => 'admin',
              :username   => 'admin',
              :properties => {
                'jcr:primaryType' => 'nt:unstructured',
                'jcr:title' => 'new title',
                'jcr:createdBy' => 'admin'
              }
            )
          end

          params = {
            'jcr:title' => 'new title'
          }

          it_should_behave_like(
            'flush_posts',
            :path => '/path/to/resource',
            :present => true,
            :form_params => params
          )
        end

        describe 'nested hash' do
          let(:resource) do
            Puppet::Type.type(:aem_sling_resource).new(
              :name       => '/path/to/resource',
              :ensure     => :present,
              :home       => '/opt/aem',
              :password   => 'admin',
              :username   => 'admin',
              :properties => {
                'jcr:title'   => 'new title',
                'jcr:content' => {
                  'title' => 'Not Agent Title'
                }
              }
            )
          end

          params = {
            'jcr:title'         => 'new title',
            'jcr:content/title' => 'Not Agent Title'
          }

          it_should_behave_like(
            'flush_posts',
            :path => '/path/to/resource',
            :depth => 2,
            :present => true,
            :form_params => params
          )
        end

        describe 'nested hash and protected/ignored properties' do
          let(:resource) do
            Puppet::Type.type(:aem_sling_resource).new(
              :name       => '/path/to/resource',
              :ensure     => :present,
              :home       => '/opt/aem',
              :password   => 'admin',
              :username   => 'admin',
              :properties => {
                'jcr:title'     => 'new title',
                'jcr:createdBy' => 'admin',
                'jcr:content'   => {
                  'jcr:primaryType' => 'cq:PageContent',
                  'title'           => 'Not Agent Title',
                  'jcr:createdBy'   => 'admin'
                }
              }
            )
          end

          params = {
            'jcr:title'                   => 'new title',
            'jcr:content/title'           => 'Not Agent Title'
          }

          it_should_behave_like(
            'flush_posts',
            :path => '/path/to/resource',
            :depth => 2,
            :present => true,
            :form_params => params
          )
        end

        describe 'arbitrary nested hash and protected/ignored properties' do
          let(:resource) do
            Puppet::Type.type(:aem_sling_resource).new(
              :name       => '/path/to/resource',
              :ensure     => :present,
              :home       => '/opt/aem',
              :password   => 'admin',
              :username   => 'admin',
              :properties => {
                'jcr:title'     => 'new title',
                'jcr:createdBy' => 'admin',
                'jcr:content'   => {
                  'jcr:primaryType' => 'cq:PageContent',
                  'title'           => 'Not Agent Title',
                  'jcr:createdBy'   => 'admin',
                  'par'             => {
                    'jcr:primaryType' => 'oak:unstructured',
                    'newprop'         => 'new prop value',
                    'jcr:created'     => 'Some date'
                  }
                }
              }
            )
          end

          params = {
            'jcr:title'                       => 'new title',
            'jcr:content/title'               => 'Not Agent Title',
            'jcr:content/par/newprop'         => 'new prop value'
          }

          it_should_behave_like(
            'flush_posts',
            :path => '/path/to/resource',
            :depth => 3,
            :present => true,
            :form_params => params
          )
        end

        describe 'passwords not forced' do
          let(:resource) do
            Puppet::Type.type(:aem_sling_resource).new(
              :name                => '/path/to/resource',
              :ensure              => :present,
              :home                => '/opt/aem',
              :password            => 'admin',
              :password_properties => ['apassword', 'anotherpassword', 'onemorepassword'],
              :username            => 'admin',
              :properties          => {
                'title'           => 'Page Title',
                'apassword'       => 'newvalue',
                'jcr:content'     => {
                  'jcr:title'       => 'Default Agent',
                  'anotherpassword' => 'newvale',
                  'par' => {
                    'property'        => 'new prop value',
                    'onemorepassword' => 'newvalue'
                  }
                }
              }
            )
          end

          params = {
            'title'                    => 'Page Title',
            'jcr:content/jcr:title'    => 'Default Agent',
            'jcr:content/par/property' => 'new prop value'
          }

          it_should_behave_like(
            'flush_posts',
            :depth => 3,
            :path => '/path/to/resource',
            :present => true,
            :form_params => params
          )
        end

        describe 'passwords forced' do
          let(:resource) do
            Puppet::Type.type(:aem_sling_resource).new(
              :name                => '/path/to/resource',
              :ensure              => :present,
              :force_passwords     => :true,
              :home                => '/opt/aem',
              :password            => 'admin',
              :password_properties => ['apassword', 'anotherpassword', 'onemorepassword'],
              :username            => 'admin',
              :properties          => {
                'title'           => 'Page Title',
                'apassword'       => 'newvalue',
                'jcr:content'     => {
                  'jcr:title'       => 'Default Agent',
                  'anotherpassword' => 'newvalue',
                  'par' => {
                    'property'        => 'new prop value',
                    'onemorepassword' => 'newvalue'
                  }
                }
              }
            )
          end

          params = {
            'title'                                  => 'Page Title',
            'apassword'                              => 'newvalue',
            'jcr:content/jcr:title'                  => 'Default Agent',
            'jcr:content/anotherpassword'            => 'newvalue',
            'jcr:content/par/property'               => 'new prop value',
            'jcr:content/par/onemorepassword'        => 'newvalue'
          }

          it_should_behave_like(
            'flush_posts',
            :depth => 3,
            :path => '/path/to/resource',
            :present => true,
            :form_params => params
          )
        end

        describe 'passwords forced and not in "should"' do
          let(:resource) do
            Puppet::Type.type(:aem_sling_resource).new(
              :name                => '/path/to/resource',
              :ensure              => :present,
              :force_passwords     => :true,
              :home                => '/opt/aem',
              :password            => 'admin',
              :password_properties => ['apassword', 'anotherpassword', 'onemorepassword'],
              :username            => 'admin',
              :properties          => {
                'title'           => 'Page Title',
                'jcr:content'     => {
                  'jcr:title' => 'Default Agent',
                  'par'       => {
                    'property' => 'new prop value'
                  }
                }
              }
            )
          end

          params = {
            'title'                    => 'Page Title',
            'jcr:content/jcr:title'    => 'Default Agent',
            'jcr:content/par/property' => 'new prop value'
          }

          it_should_behave_like(
            'flush_posts',
            :depth => 3,
            :path => '/path/to/resource',
            :present => true,
            :form_params => params
          )
        end

        describe 'using path' do
          let(:resource) do
            Puppet::Type.type(:aem_sling_resource).new(
              :name       => 'Not A Path',
              :path       => '/path/to/resource',
              :ensure     => :present,
              :home       => '/opt/aem',
              :password   => 'admin',
              :username   => 'admin',
              :properties => {
                'jcr:title' => 'new title'
              }
            )
          end

          params = 'jcr%3Atitle=new+title'

          it_should_behave_like(
            'flush_posts',
            :path => '/path/to/resource',
            :present => true,
            :form_params => params
          )
        end

        describe 'array because webmock has issues matching array in a hash for parameters' do
          let(:resource) do
            Puppet::Type.type(:aem_sling_resource).new(
              :name       => '/path/to/resource',
              :ensure     => :present,
              :home       => '/opt/aem',
              :password   => 'admin',
              :username   => 'admin',
              :properties => {
                'jcr:title'     => 'new title',
                'jcr:createdBy' => 'admin',
                'jcr:content'   => {
                  'jcr:primaryType' => 'nt:unstructured',
                  'title'           => 'Not Agent Title',
                  'jcr:createdBy'   => 'admin',
                  'par'             => {
                    'jcr:primaryType' => 'nt:unstructured',
                    'newprop'         => 'new prop value',
                    'array'           => ['this', 'is', 'an', 'array']
                  }
                }
              }
            )
          end

          params = 'jcr%3Atitle=new+title'
          params += '&jcr%3Acontent%2Ftitle=Not+Agent+Title'
          params += '&jcr%3Acontent%2Fpar%2Fnewprop=new+prop+value'
          params += '&jcr%3Acontent%2Fpar%2Farray=this'
          params += '&jcr%3Acontent%2Fpar%2Farray=is'
          params += '&jcr%3Acontent%2Fpar%2Farray=an'
          params += '&jcr%3Acontent%2Fpar%2Farray=array'

          it_should_behave_like(
            'flush_posts',
            :path => '/path/to/resource',
            :depth => 3,
            :present => true,
            :form_params => params
          )
        end
      end
    end

    describe 'flush post errors' do
      it 'should generate an error' do
        WebMock.reset!

        envdata = <<-EOF
PORT=4502
        EOF

        expect(File).to receive(:foreach).with('/opt/aem/crx-quickstart/bin/start-env').and_yield(envdata)

        uri_s = 'http://localhost:4502/etc/testcontent/nodename.1.json'
        uri = URI(uri_s)

        get_stub = stub_request(
          :get, "#{uri.scheme}://#{uri.host}:#{uri.port}#{uri.path}"
        ).with(
          :headers => { 'Authorization' => 'Basic YWRtaW46YWRtaW4=' }
        ).to_return(:status => 200, :body => content_data)

        post_stub = stub_request(
          :post, 'http://localhost:4502/etc/testcontent/nodename'
        ).with(
          :headers => { 'Authorization' => 'Basic YWRtaW46YWRtaW4=' },
          :body => { ':operation' => 'delete' }
        ).to_return(:status => 500)

        # Populate property hash
        provider.exists?
        provider.destroy
        expect { provider.flush }.to raise_error(/500/)
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

        uri_s = 'http://localhost:4502/etc/testcontent/nodename.1.json'
        uri = URI(uri_s)

        get_stub = stub_request(
          :get, "#{uri.scheme}://#{uri.host}:#{uri.port}#{uri.path}"
        ).with(
          :headers => { 'Authorization' => 'Basic YWRtaW46YWRtaW4=' }
        ).to_timeout

        # Populate property hash
        expect { provider.exists? }.to raise_error(/expired/)
        expect(get_stub).to have_been_requested.at_least_times(1)
      end
    end
  end

end
