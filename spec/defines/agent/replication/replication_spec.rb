require 'spec_helper'

# Tests for the env script management based on parameters
describe 'aem::agent::replication', :type => :defines do

  let(:default_params) do
    {
      :ensure         => 'present',
      :home           => '/opt/aem',
      :name           => 'agentname',
      :password       => 'password',
      :resource_type  => 'cq/replication/components/agent',
      :runmode        => 'author',
      :serialize_type => 'durbo',
      :template       => '/libs/cq/replication/templates/agent',
      :username       => 'username'
    }
  end

  let(:title) do
    'Agent Title'
  end

  let(:default_desc) do
    '**Managed by Puppet. Any changes made will be overwritten** '
  end

  describe 'ensure absent' do
    context 'should work without error' do
      let(:params) do
        {
          :ensure   => 'absent',
          :home     => '/opt/aem',
          :name     => 'agentname',
          :password => 'password',
          :runmode  => 'custommode',
          :username => 'username'
        }
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_aem_sling_resource(
          'Agent Title'
        ).with(
          :ensure         => 'absent',
          :handle_missing => :remove,
          :home           => '/opt/aem',
          :password       => 'password',
          :path           => '/etc/replication/agents.custommode/agentname',
          :username       => 'username'
        )
      end
    end
  end

  describe 'ensure present' do
    context 'default parameters' do
      let(:params) { default_params }
      it { is_expected.to compile }
      it do
        is_expected.to contain_aem_sling_resource(
          'Agent Title'
        ).with(
          :ensure         => 'present',
          :handle_missing => :remove,
          :home           => '/opt/aem',
          :password       => 'password',
          :path           => '/etc/replication/agents.author/agentname',
          :properties     => {
            'jcr:primaryType' => 'cq:Page',
            'jcr:content'     => {
              '_charset_'          => 'utf-8',
              'jcr:primaryType'    => 'nt:unstructured',
              'jcr:description'    => default_desc,
              'enabled'            => true,
              'logLevel'           => 'info',
              'sling:resourceType' => 'cq/replication/components/agent',
              'serializationType'  => 'durbo',
              'cq:template'        => '/libs/cq/replication/templates/agent',
              'jcr:title'          => 'Agent Title'
            }
          },
          :username => 'username'
        )
      end
    end

    context 'context root' do
      let(:params) do
        default_params.merge(:context_root => 'context')
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_aem_sling_resource(
          'Agent Title'
        ).with(
          :ensure         => 'present',
          :handle_missing => :remove,
          :home           => '/opt/aem',
          :password       => 'password',
          :path           => '/context/etc/replication/agents.author/agentname',
          :properties     => {
            'jcr:primaryType' => 'cq:Page',
            'jcr:content'     => {
              '_charset_'          => 'utf-8',
              'jcr:primaryType'    => 'nt:unstructured',
              'jcr:description'    => default_desc,
              'enabled'            => true,
              'logLevel'           => 'info',
              'sling:resourceType' => 'cq/replication/components/agent',
              'serializationType'  => 'durbo',
              'cq:template'        => '/libs/cq/replication/templates/agent',
              'jcr:title'          => 'Agent Title'
            }
          },
          :username => 'username'
        )
      end
    end

    context 'custom description' do
      let(:params) do
        default_params.merge(:description => 'Custom Description Addition')
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_aem_sling_resource(
          'Agent Title'
        ).with(
          :ensure         => 'present',
          :handle_missing => :remove,
          :home           => '/opt/aem',
          :password       => 'password',
          :path           => '/etc/replication/agents.author/agentname',
          :properties     => {
            'jcr:primaryType' => 'cq:Page',
            'jcr:content'     => {
              '_charset_'          => 'utf-8',
              'jcr:primaryType'    => 'nt:unstructured',
              'jcr:description'    => "#{default_desc}Custom Description Addition",
              'enabled'            => true,
              'logLevel'           => 'info',
              'sling:resourceType' => 'cq/replication/components/agent',
              'serializationType'  => 'durbo',
              'cq:template'        => '/libs/cq/replication/templates/agent',
              'jcr:title'          => 'Agent Title'
            }
          },
          :username => 'username'
        )
      end
    end

    context 'all parameters' do
      let(:params) do
        {
          :agent_user            => 'agentuser',
          :batch_enabled         => true,
          :batch_max_wait        => 60,
          :batch_trigger_size    => 100,
          :context_root          => 'context_root',
          :description           => 'Custom Description',
          :enabled               => false,
          :home                  => '/opt/aem',
          :log_level             => 'debug',
          :name                  => 'customname',
          :password              => 'apassword',
          :protocol_close_conn   => true,
          :protocol_conn_timeout => 1000,
          :protocol_http_headers => ['CQ-Action:{action}', 'CQ-Handle:{path}', 'CQ-Path:{path}'],
          :protocol_http_method  => 'POST',
          :protocol_interface    => '127.0.0.1',
          :protocol_sock_timeout => 1_000,
          :protocol_version      => 1.0,
          :proxy_host            => 'proxy.domain.com',
          :proxy_ntlm_domain     => 'proxydomain',
          :proxy_ntlm_host       => 'proxy.ntlm.domain.com',
          :proxy_password        => 'proxypassword',
          :proxy_port            => 12_345,
          :proxy_user            => 'proxyuser',
          :resource_type         => 'cq/replication/components/revagent',
          :retry_delay           => 60,
          :reverse               => true,
          :runmode               => 'custommode',
          :serialize_type        => 'flush',
          :static_directory      => '/var/path',
          :static_definition     => '/content/geo* ${path}.html?wcmmode=preview',
          :template              => '/libs/cq/replication/templates/revagent',
          :trans_allow_exp_cert  => true,
          :trans_ntlm_domain     => 'transdomain',
          :trans_ntlm_host       => 'trans.ntlm.domain.com',
          :trans_password        => 'transpassword',
          :trans_ssl             => 'relaxed',
          :trans_uri             => 'http://localhost:4503/bin/receive?sling:authRequestLogin=1',
          :trans_user            => 'transuser',
          :trigger_ignore_def    => true,
          :trigger_no_status     => false,
          :trigger_no_version    => true,
          :trigger_on_dist       => true,
          :trigger_on_mod        => true,
          :trigger_on_receive    => true,
          :trigger_onoff_time    => true,
          :username              => 'ausername'
        }
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_aem_sling_resource(
          'Agent Title'
        ).with(
          :ensure         => 'present',
          :handle_missing => :remove,
          :home           => '/opt/aem',
          :password       => 'apassword',
          :path           => '/context_root/etc/replication/agents.custommode/customname',
          :properties     => {
            'jcr:primaryType' => 'cq:Page',
            'jcr:content'     => {
              '_charset_'                   => 'utf-8',
              'jcr:primaryType'             => 'nt:unstructured',
              'userId'                      => 'agentuser',
              'queueBatchMode'              => true,
              'queueBatchWaitTime'          => 60,
              'queueBatchMaxSize'           => 100,
              'jcr:description'             => "#{default_desc}Custom Description",
              'enabled'                     => false,
              'logLevel'                    => 'debug',
              'protocolHTTPConnectionClose' => true,
              'protocolConnectTimeout'      => 1000,
              #:protocol_http_headers => ['CQ-Action:{action}', 'CQ-Handle:{path}', 'CQ-Path:{path}'],
              'protocolHTTPMethod'          => 'POST',
              'protocolInterface'           => '127.0.0.1',
              'protocolSocketTimeout'       => 1_000,
              'protocolVersion'             => 1.0,
              'proxyHost'                   => 'proxy.domain.com',
              'proxyNTLMDomain'             => 'proxydomain',
              'proxyNTLMHost'               => 'proxy.ntlm.domain.com',
              'proxyPassword'               => 'proxypassword',
              'proxyPort'                   => 12_345,
              'proxyUser'                   => 'proxyuser',
              'sling:resourceType'          => 'cq/replication/components/revagent',
              'retryDelay'                  => 60,
              'reverseReplication'          => true,
              'serializationType'           => 'flush',
              'directory'                   => '/var/path',
              'definition'                  => '/content/geo* ${path}.html?wcmmode=preview',
              'cq:template'                 => '/libs/cq/replication/templates/revagent',
              'jcr:title'                   => 'Agent Title',
              'protocolHTTPExpired'         => true,
              'transportNTLMDomain'         => 'transdomain',
              'transportNTLMHost'           => 'trans.ntlm.domain.com',
              'transportPassword'           => 'transpassword',
              'transportUri'                => 'http://localhost:4503/bin/receive?sling:authRequestLogin=1',
              'transportUser'               => 'transuser',
              'ssl'                         => 'relaxed',
              'triggerSpecific'             => true,
              'noStatusUpdate'              => false,
              'noVersioning'                => true,
              'triggerDistribute'           => true,
              'triggerModified'             => true,
              'triggerReceive'              => true,
              'triggerOnOffTime'            => true
            }
          },
          :username => 'ausername'
        )
      end
    end
  end
end
