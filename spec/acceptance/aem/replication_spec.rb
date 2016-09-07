require 'spec_helper_acceptance'

describe 'create replication agent', license: false do

  let(:facts) do
    {
      environment: :root
    }
  end

  include_examples 'setup aem'

  let(:desc) do
    '**Managed by Puppet. Any changes made will be overwritten** Custom Description'
  end

  it 'should create with all properties' do
    site = <<-MANIFEST
      'node \"agent\" {
        File { backup => false, owner => \"aem\", group => \"aem\" }

        aem::agent::replication { \"Agent Title\" :
          agent_user            => \"agentuser\",
          batch_enabled         => true,
          batch_max_wait        => 60,
          batch_trigger_size    => 100,
          description           => \"Custom Description\",
          enabled               => false,
          home                  => \"/opt/aem/author\",
          log_level             => \"debug\",
          mixin_types           => [\"cq:ReplicationStatus\"],
          name                  => \"customname\",
          password              => \"admin\",
          protocol_close_conn   => true,
          protocol_conn_timeout => 1000,
          protocol_http_headers => [\"CQ-Action:{action}\", \"CQ-Handle:{path}\", \"CQ-Path:{path}\"],
          protocol_http_method  => \"POST\",
          protocol_interface    => \"127.0.0.1\",
          protocol_sock_timeout => 1000,
          protocol_version      => 1.0,
          proxy_host            => \"proxy.domain.com\",
          proxy_ntlm_domain     => \"proxydomain\",
          proxy_ntlm_host       => \"proxy.ntlm.domain.com\",
          proxy_password        => \"proxypassword\",
          proxy_port            => 12345,
          proxy_user            => \"proxyuser\",
          resource_type         => \"cq/replication/components/revagent\",
          retry_delay           => 60,
          reverse               => true,
          runmode               => \"author\",
          serialize_type        => \"flush\",
          static_directory      => \"/var/path\",
          static_definition     => \"/content/geo* \\${path}.html?wcmmode=preview\",
          template              => \"/libs/cq/replication/templates/revagent\",
          timeout               => 120,
          trans_allow_exp_cert  => true,
          trans_ntlm_domain     => \"transdomain\",
          trans_ntlm_host       => \"trans.ntlm.domain.com\",
          trans_password        => \"transpassword\",
          trans_ssl             => \"relaxed\",
          trans_uri             => \"http://localhost:4503/bin/receive?sling:authRequestLogin=1\",
          trans_user            => \"transuser\",
          trigger_ignore_def    => true,
          trigger_no_status     => false,
          trigger_no_version    => true,
          trigger_on_dist       => true,
          trigger_on_mod        => true,
          trigger_on_receive    => true,
          trigger_onoff_time    => true,
          username              => \"admin\"
        }
      }'
    MANIFEST

    pp = <<-MANIFEST
      file {
        '#{master.puppet['codedir']}/environments/production/manifests/site.pp':
          ensure => file,
          content => #{site}
      }
    MANIFEST

    apply_manifest_on(master, pp, catch_failures: true)
    restart_puppetserver
    fqdn = on(master, 'facter fqdn').stdout.strip
    fqdn = fqdn.chop if fqdn.end_with?('.')

    on(
      default,
      puppet("agent --detailed-exitcodes --onetime --no-daemonize --debug --verbose --server #{fqdn}"),
      acceptable_exit_codes: [0, 2]
    )

    on(
      default,
      puppet("agent --detailed-exitcodes --onetime --no-daemonize --debug --verbose --server #{fqdn}"),
      acceptable_exit_codes: [0]
    )
    cmd = 'curl http://localhost:4502/etc/replication/agents.author/customname.infinity.json '
    cmd += '-u admin:admin'
    shell(cmd) do |result|
      jsonresult = JSON.parse(result.stdout)

      expect(jsonresult['jcr:primaryType']).to eq('cq:Page')
      expect(jsonresult['jcr:content']['jcr:primaryType']).to eq('nt:unstructured')
      expect(jsonresult['jcr:content']['userId']).to eq('agentuser')
      expect(jsonresult['jcr:content']['queueBatchMode']).to eq('true')
      expect(jsonresult['jcr:content']['queueBatchWaitTime']).to eq('60')
      expect(jsonresult['jcr:content']['queueBatchMaxSize']).to eq('100')
      expect(jsonresult['jcr:content']['jcr:description']).to eq(desc)
      expect(jsonresult['jcr:content']['enabled']).to eq('false')
      expect(jsonresult['jcr:content']['logLevel']).to eq('debug')
      expect(jsonresult['jcr:content']['jcr:mixinTypes']).to match_array(['cq:ReplicationStatus'])
      expect(jsonresult['jcr:content']['protocolHTTPConnectionClose']).to eq('true')
      expect(jsonresult['jcr:content']['protocolConnectTimeout']).to eq('1000')
      expect(
        jsonresult['jcr:content']['protocolHTTPHeaders']
      ).to match_array(['CQ-Action:{action}', 'CQ-Handle:{path}', 'CQ-Path:{path}'])
      expect(jsonresult['jcr:content']['protocolHTTPMethod']).to eq('POST')
      expect(jsonresult['jcr:content']['protocolInterface']).to eq('127.0.0.1')
      expect(jsonresult['jcr:content']['protocolSocketTimeout']).to eq('1000')
      expect(jsonresult['jcr:content']['protocolVersion']).to eq('1.0')
      expect(jsonresult['jcr:content']['proxyHost']).to eq('proxy.domain.com')
      expect(jsonresult['jcr:content']['proxyNTLMDomain']).to eq('proxydomain')
      expect(jsonresult['jcr:content']['proxyNTLMHost']).to eq('proxy.ntlm.domain.com')
      expect(jsonresult['jcr:content']['proxyPassword']).to_not be_nil
      expect(jsonresult['jcr:content']['proxyPort']).to eq('12345')
      expect(jsonresult['jcr:content']['proxyUser']).to eq('proxyuser')
      expect(jsonresult['jcr:content']['sling:resourceType']).to eq('cq/replication/components/revagent')
      expect(jsonresult['jcr:content']['retryDelay']).to eq('60')
      expect(jsonresult['jcr:content']['reverseReplication']).to eq('true')
      expect(jsonresult['jcr:content']['serializationType']).to eq('flush')
      expect(jsonresult['jcr:content']['directory']).to eq('/var/path')
      expect(jsonresult['jcr:content']['definition']).to eq('/content/geo* ${path}.html?wcmmode=preview')
      expect(jsonresult['jcr:content']['cq:template']).to eq('/libs/cq/replication/templates/revagent')
      expect(jsonresult['jcr:content']['jcr:title']).to eq('Agent Title')
      expect(jsonresult['jcr:content']['protocolHTTPExpired']).to eq('true')
      expect(jsonresult['jcr:content']['transportNTLMDomain']).to eq('transdomain')
      expect(jsonresult['jcr:content']['transportNTLMHost']).to eq('trans.ntlm.domain.com')
      expect(jsonresult['jcr:content']['transportPassword']).to_not be_nil
      expect(jsonresult['jcr:content']['transportUri']).to eq('http://localhost:4503/bin/receive?sling:authRequestLogin=1')
      expect(jsonresult['jcr:content']['transportUser']).to eq('transuser')
      expect(jsonresult['jcr:content']['directory']).to eq('/var/path')
      expect(jsonresult['jcr:content']['ssl']).to eq('relaxed')
      expect(jsonresult['jcr:content']['triggerSpecific']).to eq('true')
      expect(jsonresult['jcr:content']['noStatusUpdate']).to eq('false')
      expect(jsonresult['jcr:content']['noVersioning']).to eq('true')
      expect(jsonresult['jcr:content']['triggerDistribute']).to eq('true')
      expect(jsonresult['jcr:content']['triggerModified']).to eq('true')
      expect(jsonresult['jcr:content']['triggerReceive']).to eq('true')
      expect(jsonresult['jcr:content']['triggerOnOffTime']).to eq('true')
    end
  end
end
