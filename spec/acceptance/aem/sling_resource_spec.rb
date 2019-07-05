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

describe 'sling resource', license: false do

  context 'create' do
    it 'should work with no errors' do
      step 'Setup' do
        manifest('/vagrant/puppet/files/manifests/aem/sling/create_run.pp')
        agent
      end
      step 'Run Test' do
        cmd = 'curl http://localhost:4502/content/testnode.infinity.json '
        cmd += '-u admin:admin'
        shell(cmd) do |result|
          jsonresult = JSON.parse(result.stdout)

          expect(jsonresult['title']).to eq('title string')
          expect(jsonresult['text']).to eq('text string')
          expect(jsonresult['child']['property']).to eq('value')
          expect(jsonresult['child']['grandchild']['child attrib']).to eq('another value')
          expect(jsonresult['child']['grandchild']['array']).to eq(%w[this is an array])
        end
      end
    end
  end

  context 'update' do
    it 'handle_missing == ignore' do
      step 'Setup' do
        manifest('/vagrant/puppet/files/manifests/aem/sling/update_ignore_run.pp')
        agent
      end
      step 'Run Test' do

        cmd = 'curl http://localhost:4502/content/testnode.infinity.json '
        cmd += '-u admin:admin'
        shell(cmd) do |result|
          jsonresult = JSON.parse(result.stdout)

          expect(jsonresult['title']).to eq('title string')
          expect(jsonresult['text']).to eq('text string')
          expect(jsonresult['child']['property']).to eq('value')
          expect(jsonresult['child']['grandchild']['child attrib']).to eq('another value')
          expect(jsonresult['child']['grandchild']['array']).to eq(%w[this is an array])

          expect(jsonresult['child']['anotherproperty']).to eq('value')
          expect(jsonresult['child']['grandchild2']['child attrib']).to eq('another value')
          expect(jsonresult['child']['grandchild2']['array']).to eq(%w[this is an array])

          expect(jsonresult['jcr:title']).to eq('title string')
          expect(jsonresult['newtext']).to eq('text string')
          expect(jsonresult['child2']['property']).to eq('value')
          expect(jsonresult['child2']['grandchild']['child attrib']).to eq('another value')
          expect(jsonresult['child2']['grandchild']['array']).to eq(%w[this is an array])
        end
      end
    end

    it 'handle_missing == remove' do
      step 'Setup' do
        manifest('/vagrant/puppet/files/manifests/aem/sling/update_remove_run.pp')
        agent
      end
      step 'Run Test' do

        cmd = 'curl http://localhost:4502/content/testnode.infinity.json '
        cmd += '-u admin:admin'
        shell(cmd) do |result|
          jsonresult = JSON.parse(result.stdout)

          expect(jsonresult['title']).to be_nil
          expect(jsonresult['text']).to be_nil
          expect(jsonresult['child']['property']).to be_nil
          expect(jsonresult['child']['grandchild']).to be_nil

          expect(jsonresult['child']['anotherproperty']).to eq('new value')
          expect(jsonresult['child']['grandchild2']['child attrib']).to eq('changed value')
          expect(jsonresult['child']['grandchild2']['array']).to eq(%w[this is a longer array])

          expect(jsonresult['jcr:title']).to eq('title string')
          expect(jsonresult['newtext']).to eq('text string')
          expect(jsonresult['child2']['property']).to eq('value')
          expect(jsonresult['child2']['grandchild']['child attrib']).to eq('another value')
          expect(jsonresult['child2']['grandchild']['array']).to be_nil
        end
      end
    end
  end

  context 'destroy' do

    it 'should work with no errors' do
      step 'Setup' do
        manifest('/vagrant/puppet/files/manifests/aem/sling/remove_run.pp')
        agent
      end
      step 'Run Test' do

        cmd = 'curl http://localhost:4502/content/testnode.infinity.json '
        cmd += '-u admin:admin'
        shell(cmd) do |result|
          expect(result.stdout).to match(/404/)
        end
      end
    end
  end
end
