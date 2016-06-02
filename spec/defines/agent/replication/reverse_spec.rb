require 'spec_helper'

# Tests for the env script management based on parameters
describe 'aem::agent::replication::reverse', :type => :defines do

  let(:default_params) do
    {
      :home           => '/opt/aem',
      :name           => 'agentname',
      :password       => 'password',
      :runmode        => 'author',
      :username       => 'username'
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
          :enabled             => true,
          :ensure              => 'present',
          :home                => '/opt/aem',
          :log_level           => 'info',
          :name                => 'agentname',
          :password            => 'password',
          :password_properties => ['transportPassword', 'proxyPassword'],
          :resource_type       => 'cq/replication/components/revagent',
          :reverse             => true,
          :runmode             => 'author',
          :serialize_type      => 'durbo',
          :template            => '/libs/cq/replication/templates/revagent',
          :username            => 'username'
        )
      end
    end
    context 'all values' do
      let(:params) do
        default_params.update(
          :agent_user           => 'agentuser',
          :context_root         => 'contextroot',
          :description          => 'description',
          :enabled              => false,
          :ensure               => 'present',
          :home                 => '/opt/aem',
          :log_level            => 'error',
          :name                 => 'agentname',
          :password             => 'password',
          :runmode              => 'author',
          :timeout              => 2000,
          :trans_allow_exp_cert => true,
          :trans_password       => 'transpassword',
          :trans_ssl            => 'relaxed',
          :trans_uri            => 'http://hostname:port/bin/receive',
          :trans_user           => 'transuser',
          :username             => 'username'
        )
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_aem__agent__replication(
          'Agent Title'
        ).only_with(
          :agent_user           => 'agentuser',
          :context_root         => 'contextroot',
          :description          => 'description',
          :enabled              => false,
          :ensure               => 'present',
          :home                 => '/opt/aem',
          :log_level            => 'error',
          :name                 => 'agentname',
          :password             => 'password',
          :password_properties => ['transportPassword', 'proxyPassword'],
          :resource_type        => 'cq/replication/components/revagent',
          :runmode              => 'author',
          :reverse              => true,
          :serialize_type       => 'durbo',
          :template             => '/libs/cq/replication/templates/revagent',
          :timeout              => 2000,
          :trans_allow_exp_cert => true,
          :trans_password       => 'transpassword',
          :trans_ssl            => 'relaxed',
          :trans_uri            => 'http://hostname:port/bin/receive',
          :trans_user           => 'transuser',
          :username             => 'username'
        )
      end
    end
  end

  describe 'ensure absent' do
    context 'should work without error' do
      let(:params) do
        default_params.update(:ensure => 'absent')
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_aem__agent__replication(
          'Agent Title'
        ).only_with(
          :enabled             => true,
          :ensure              => 'absent',
          :home                => '/opt/aem',
          :log_level           => 'info',
          :name                => 'agentname',
          :password            => 'password',
          :password_properties => ['transportPassword', 'proxyPassword'],
          :resource_type       => 'cq/replication/components/revagent',
          :reverse             => true,
          :runmode             => 'author',
          :serialize_type      => 'durbo',
          :template            => '/libs/cq/replication/templates/revagent',
          :username            => 'username'
        )
      end
    end
  end
end
