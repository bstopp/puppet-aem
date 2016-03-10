require 'spec_helper'

# Tests for the env script management based on parameters
describe 'aem::agent::config', :type => :defines do

  let(:title) do
    'agent'
  end

  let(:default_params) do
    {
      :home => '/opt/aem'
    }
  end

  describe 'parameter validation' do

    context 'ensure' do

      context 'absent' do
        let(:params) do
          default_params.merge(:ensure => 'absent')
        end
        it { is_expected.to compile }
      end

      context 'present' do
        let(:params) do
          default_params.merge(:ensure => 'absent')
        end
        it { is_expected.to compile }
      end

      context 'invalid' do
        let(:params) do
          default_params.merge(:ensure => 'invalid')
        end

        it { expect { is_expected.to compile }.to raise_error(/not supported for ensure/) }
      end
    end

    context 'home' do

      context 'not specified' do
        let(:params) do
          tmp = default_params.clone
          tmp.delete(:home)
          tmp
        end
        it { expect { is_expected.to compile }.to raise_error(/is not an absolute path/) }
      end

      context 'not absolute' do
        let(:params) do
          default_params.merge(:home => 'not/absolute/path')
        end
        it { expect { is_expected.to compile }.to raise_error(/is not an absolute path/) }
      end

    end

    context 'status' do

      context 'enabled' do
        let:params do
          default_params.merge(:status => 'enabled')
        end
        it { is_expected.to compile }
      end

      context 'disabled' do
        let:params do
          default_params.merge(:status => 'disabled')
        end
        it { is_expected.to compile }
      end

      context 'invalid' do
        let:params do
          default_params.merge(:status => 'invalid')
        end
        it { expect { is_expected.to compile }.to raise_error(/not supported for status/) }
      end

    end

    context 'handle_missing' do

      context 'ignore' do
        let:params do
          default_params.merge(:handle_missing => 'ignore')
        end
        it { is_expected.to compile }
      end

      context 'remove' do
        let(:params) do
          default_params.merge(:handle_missing => 'remove')
        end

        it { is_expected.to compile }
      end

      context 'invalid' do
        let(:params) do
          default_params.merge(:handle_missing => 'invalid')
        end

        it { expect { is_expected.to compile }.to raise_error(/not supported for handle_missing/) }
      end
    end

    context 'template' do

      context 'valid' do
        let(:params) do
          default_params.merge(:template => '/foo/bar')
        end

        it { is_expected.to compile }
      end

      context 'invlid' do
        let(:params) do
          default_params.merge(:template => 'foo/bar')
        end

        it { expect { is_expected.to compile }.to raise_error(/should be a absolute path starting with/) }
      end

    end

  end

  describe 'defines resource' do

    let(:properties) do
      {
        'jcr:primaryType' => 'cq:Page',
        'jcr:content'     => {
          'jcr:primaryType'    => 'nt:unstructured',
          'cq:template'        => '/libs/cq/replication/templates/agent',
          '_charset_'          => 'utf-8',
          ':status'            => 'browser',
          'enabled'            => true,
          'jcr:description'    => 'Replication Agent',
          'jcr:title'          => 'Replication Agent',
          'logLevel'           => 'info',
          'retryDelay'         => '6000',
          'serializationType'  => 'durbo',
          'sling:resourceType' => 'cq/replication/components/agent',
          'transportPassword'  => 'password',
          'transportUri'       => 'http://host:port/bin/receive?sling:authRequestLogin=1',
          'transportUser'      => 'replication-receiver',
          'userId'             => 'your_replication_user'
        }
      }
    end

    let(:params) do
      default_params.merge(:home => '/opt/aem')
    end

    context 'default params' do
      it { is_expected.to compile }
      it do
        is_expected.to contain_aem_sling_resource(
          'agent'
        ).with(
          :ensure            => 'present',
          :path              => '/etc/replication/agents.author/agent',
          :handle_missing    => 'ignore',
          :home              => '/opt/aem',
          :username          => 'admin',
          :password          => 'admin',
          :properties        => properties
        )
      end
    end

    context 'ensure absent' do
      let(:params) do
        default_params.merge(:ensure => 'absent')
      end
      it { is_expected.to compile }
      it do
        is_expected.to contain_aem_sling_resource(
          'agent'
        ).with(
          :ensure            => 'absent',
          :path              => '/etc/replication/agents.author/agent',
          :handle_missing    => 'ignore',
          :home              => '/opt/aem',
          :username          => 'admin',
          :password          => 'admin',
          :properties        => properties
        )
      end
    end

  end

end
