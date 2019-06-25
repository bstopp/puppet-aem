# frozen_string_literal: true

require 'spec_helper'

# Tests for the env script management based on parameters
describe 'aem::osgi::config' do

  let(:facts) do
    {
      kernel: 'Linux'
    }
  end

  let(:title) do
    'aem'
  end

  let(:default_params) do
    {
      home: '/opt/aem',
      handle_missing: 'merge',
      pid: 'osgi.pid',
      properties: {
        'boolean' => false,
        'long' => 123_456_789,
        'string' => 'string',
        'array' => ['an', 'array', 'of', 'values']
      },
      username: 'username',
      password: 'password'
    }
  end

  describe 'parameter validation' do

    context 'ensure' do

      context 'absent' do
        let(:params) do
          default_params.merge(ensure: 'absent', type: 'file')
        end
        it { is_expected.to compile }
      end

      context 'invalid' do
        let(:params) do
          default_params.merge(ensure: 'invalid')
        end

        it { expect { is_expected.to compile }.to raise_error(/not supported for ensure/) }
      end
    end

    context 'handle_missing' do

      context 'merge' do
        let(:params) do
          default_params.merge(type: 'console')
        end
        it { is_expected.to compile }
      end

      context 'remove' do
        let(:params) do
          default_params.merge(handle_missing: 'remove', type: 'console')
        end

        it { is_expected.to compile }
      end

      context 'invalid' do
        let(:params) do
          default_params.merge(handle_missing: 'invalid', type: 'console')
        end

        it { expect { is_expected.to compile }.to raise_error(/not supported for handle_missing/) }
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
          default_params.merge(home: 'not/absolute/path')
        end
        it { expect { is_expected.to compile }.to raise_error(/is not an absolute path/) }
      end

    end

    context 'properties' do
      context 'not specified' do
        let(:params) do
          tmp = default_params.clone
          tmp.delete(:properties)
          tmp
        end
        it { expect { is_expected.to compile }.to raise_error(/must contain at least one entry/) }
      end

      context 'not a hash' do
        let(:params) do
          default_params.merge(properties: %w[this is not a hash])
        end
        it { expect { is_expected.to compile }.to raise_error(/must be a Hash of values/) }
      end
    end

    context 'console type' do
      context 'username' do
        context 'not specified' do
          let(:params) do
            tmp = default_params.clone
            tmp[:type] = 'console'
            tmp.delete(:username)
            tmp
          end
          it { expect { is_expected.to compile }.to raise_error(/Username must be specified/) }
        end
      end

      context 'password' do
        context 'not specified' do
          let(:params) do
            tmp = default_params.clone
            tmp[:type] = 'console'
            tmp.delete(:password)
            tmp
          end
          it { expect { is_expected.to compile }.to raise_error(/Password must be specified/) }
        end
      end

    end
  end

  describe 'defines resource based on type' do

    context 'file type' do
      let(:params) do
        default_params.merge(type: 'file')
      end

      context 'default params' do
        it do
          is_expected.to contain_aem__osgi__config__file(
            'aem'
          ).only_with(
            ensure: 'present',
            group: 'aem',
            home: '/opt/aem',
            name: 'aem',
            pid: 'osgi.pid',
            properties: params[:properties],
            user: 'aem'
          )
        end
      end

      context 'ensure absent' do
        let(:params) do
          default_params.merge(ensure: 'absent', type: 'file')
        end

        it do
          is_expected.to contain_aem__osgi__config__file(
            'aem'
          ).only_with(
            ensure: 'absent',
            group: 'aem',
            home: '/opt/aem',
            name: 'aem',
            pid: 'osgi.pid',
            properties: params[:properties],
            user: 'aem'
          )
        end
      end

    end

    context 'console type' do
      let(:params) do
        default_params.merge(type: 'console')
      end

      context 'default params' do
        it { is_expected.to compile }
        it do
          is_expected.to contain_aem_osgi_config(
            'aem'
          ).only_with(
            ensure: 'present',
            configuration: params[:properties],
            handle_missing: 'merge',
            home: '/opt/aem',
            name: 'aem',
            pid: 'osgi.pid',
            password: 'password',
            username: 'username'
          )
        end
      end

      context 'ensure absent' do
        let(:params) do
          default_params.merge(ensure: 'absent', type: 'console')
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_aem_osgi_config(
            'aem'
          ).only_with(
            ensure: 'absent',
            configuration: params[:properties],
            handle_missing: 'merge',
            home: '/opt/aem',
            name: 'aem',
            pid: 'osgi.pid',
            password: 'password',
            username: 'username'
          )
        end
      end
    end

    context 'invalid type' do
      let(:params) do
        default_params.merge(type: 'invalid')

        it { is_expected.to raise_error(/not supported for type/) }
      end
    end
  end

end
