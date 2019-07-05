# frozen_string_literal: true

require 'spec_helper_acceptance'

def manifest(file)
  step 'Create Manifest' do
    pp = <<~MANIFEST
      file {
        '#{master.puppet['codedir']}/environments/production/manifests/site.pp':
          ensure => file,
          source => '#{file}'
      }
    MANIFEST
    apply_manifest_on(master, pp, catch_failures: true)
  end
end

def agent
  step 'Run Agent' do
    with_puppet_running_on(master, {}, '/tmp') do

      on(default, puppet("agent -t #{$debug} --server #{$master_fqdn}"), acceptable_exit_codes: [0, 2])
      on(default, puppet("agent -t #{$debug} --server #{$master_fqdn}"), acceptable_exit_codes: [0])
    end
  end
end

describe 'create replication agent', license: false do

  let(:desc) do
    '**Managed by Puppet. Any changes made will be overwritten** Custom Description'
  end

  it 'should create with all properties' do
    step 'Setup' do
      manifest('/vagrant/puppet/files/manifests/aem/replication.pp')
      agent
    end
    step 'Run Test' do
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
        expect(jsonresult['jcr:content']['proxyPassword']).not_to be_nil
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
        expect(jsonresult['jcr:content']['transportPassword']).not_to be_nil
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
end
