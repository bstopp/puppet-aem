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

describe 'destroy' do
  it 'should work with no errors' do
    manifest('/vagrant/puppet/files/manifests/aem/destroy.pp')
    agent
  end

  it 'should have removed instance repository' do
    on(default, "test -f /opt/aem/author/crx-quickstart", accept_all_exit_codes: true) do |result|
      assert(result.exit_code != 0)
    end
  end
end
