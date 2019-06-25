# frozen_string_literal: true

require 'spec_helper'

# Tests for the env script management based on parameters
describe 'aem::agent::replication::static' do

  let(:default_params) do
    {
      home: '/opt/aem',
      name: 'agentname',
      password: 'password',
      runmode: 'author',
      username: 'username'
    }
  end

  let(:title) do
    'Agent Title'
  end

  let(:default_desc) do
    '**Managed by Puppet. Any changes made will be overwritten** '
  end
  describe 'ensure present' do
    context 'default values' do
      let(:params) do
        default_params
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_aem__agent__replication(
          'Agent Title'
        ).only_with(
          enabled: true,
          ensure: 'present',
          home: '/opt/aem',
          log_level: 'info',
          name: 'agentname',
          password: 'password',
          resource_type: 'cq/replication/components/staticagent',
          runmode: 'author',
          serialize_type: 'static',
          template: '/libs/cq/replication/templates/staticagent',
          username: 'username'
        )
      end
    end
    context 'all values' do
      let(:params) do
        default_params.update(
          agent_user: 'agentuser',
          definition: '/content/blah/* ${path}.html?wcmmode=disabled',
          description: 'description',
          directory: '/path/to/storage',
          enabled: false,
          ensure: 'present',
          home: '/opt/aem',
          log_level: 'error',
          name: 'agentname',
          password: 'password',
          retry_delay: 30_000,
          runmode: 'author',
          username: 'username'
        )
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_aem__agent__replication(
          'Agent Title'
        ).only_with(
          agent_user: 'agentuser',
          description: 'description',
          enabled: false,
          ensure: 'present',
          home: '/opt/aem',
          log_level: 'error',
          name: 'agentname',
          password: 'password',
          resource_type: 'cq/replication/components/staticagent',
          retry_delay: 30_000,
          runmode: 'author',
          serialize_type: 'static',
          static_definition: '/content/blah/* ${path}.html?wcmmode=disabled',
          static_directory: '/path/to/storage',
          template: '/libs/cq/replication/templates/staticagent',
          username: 'username'
        )
      end
    end
  end

  describe 'ensure absent' do
    context 'should work without error' do
      let(:params) do
        default_params.update(ensure: 'absent')
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_aem__agent__replication(
          'Agent Title'
        ).only_with(
          enabled: true,
          ensure: 'absent',
          home: '/opt/aem',
          log_level: 'info',
          name: 'agentname',
          password: 'password',
          resource_type: 'cq/replication/components/staticagent',
          runmode: 'author',
          serialize_type: 'static',
          template: '/libs/cq/replication/templates/staticagent',
          username: 'username'
        )
      end
    end
  end
end
