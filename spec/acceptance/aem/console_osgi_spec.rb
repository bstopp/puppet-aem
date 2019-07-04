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

describe 'console osgi configs', license: false do

  it 'should work with no errors' do
    step 'Setup' do
      manifest('/vagrant/puppet/files/manifests/aem/osgi/console_setup.pp')
      agent
    end
  end

  it 'should handle remove existing configuration' do
    step 'Setup' do
      manifest('/vagrant/puppet/files/manifests/aem/osgi/console_remove_setup.pp')
      agent
    end
    step 'Run Test' do
      manifest('/vagrant/puppet/files/manifests/aem/osgi/console_remove_run.pp')
      agent

      step 'Test configuration' do
        cmd = 'curl http://localhost:4502/system/console/configMgr/org.apache.sling.security.impl.ReferrerFilter.json '
        cmd += '-u admin:admin'
        shell(cmd) do |result|
          jsonresult = JSON.parse(result.stdout)
          configed_props = jsonresult[0]['properties']
          expect(configed_props['allow.empty']['is_set']).to eq(false)

          expect(configed_props['allow.hosts.regexp']['is_set']).to eq(false)

          expect(configed_props['allow.hosts']['is_set']).to eq(true)
          expect(configed_props['allow.hosts']['values']).to eq(['author.localhost'])

          expect(configed_props['filter.methods']['is_set']).to eq(false)
        end
      end
    end
  end

  it 'should handle merge existing configuration' do
    step 'Setup' do
      manifest('/vagrant/puppet/files/manifests/aem/osgi/console_merge_setup.pp')
      agent
    end
    step 'Run Test' do
      manifest('/vagrant/puppet/files/manifests/aem/osgi/console_merge_run.pp')
      agent

      cmd = 'curl http://localhost:4502/system/console/configMgr/org.apache.sling.security.impl.ReferrerFilter.json '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout)
        configed_props = jsonresult[0]['properties']
        expect(configed_props['allow.empty']['is_set']).to eq(true)
        expect(configed_props['allow.empty']['value']).to eq(true)

        expect(configed_props['allow.hosts.regexp']['is_set']).to eq(false)

        expect(configed_props['allow.hosts']['is_set']).to eq(true)
        expect(configed_props['allow.hosts']['values']).to eq(['author.localhost'])

        expect(configed_props['filter.methods']['is_set']).to eq(true)
        expect(configed_props['filter.methods']['values']).to eq(['POST', 'PUT', 'DELETE', 'TRACE'])
      end
    end
  end

  it 'should delete configurations' do
    step 'Setup' do
      manifest('/vagrant/puppet/files/manifests/aem/osgi/console_delete_setup.pp')
      agent
    end
    step 'Run Test' do
      manifest('/vagrant/puppet/files/manifests/aem/osgi/console_delete_run.pp')
      agent

      cmd = 'curl -s http://localhost:4502/system/console/configMgr/org.apache.sling.security.impl.ReferrerFilter.json '
      cmd += '-u admin:admin'
      shell(cmd) do |result|
        jsonresult = JSON.parse(result.stdout)
        expect(jsonresult.empty?).to be_truthy
      end
    end
  end
end
