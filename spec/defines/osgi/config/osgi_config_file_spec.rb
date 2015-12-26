require 'spec_helper'

# Tests for the env script management based on parameters
describe 'aem::osgi::config::file', :type => :defines do

  let :facts do
    {
      :kernel => 'Linux'
    }
  end

  let :title do
    'aem'
  end

  let :default_params do
    {
      :home       => '/opt/aem',
      :properties => {
        'boolean' => false,
        'long'    => 123456789,
        'string'  => 'string',
        'array'   => ['an', 'array', 'of', 'values']
      }
    }
  end

  describe 'parameter validation' do

    context 'ensure' do

      context 'absent' do
        let :params do
          default_params.merge(:ensure => 'absent')
        end
        it { is_expected.to compile }
        it { is_expected.to contain_file('/opt/aem/crx-quickstart/install/aem.config').with('ensure' => 'absent') }
      end

      context 'invalid' do
        let :params do
          default_params.merge(:ensure => 'invalid')
        end

        it { expect { is_expected.to compile }.to raise_error(/not supported for ensure/) }
      end
    end

    context 'home' do

      context 'not specified' do
        let :params do
          tmp = default_params.clone
          tmp.delete(:home)
          tmp
        end
        it { expect { is_expected.to compile }.to raise_error(/is not an absolute path/) }
      end

      context 'not absolute' do
        let :params do
          default_params.merge(:home => 'not/absolute/path')
        end
        it { expect { is_expected.to compile }.to raise_error(/is not an absolute path/) }
      end

    end

    context 'properties' do
      context 'not specifed' do
        let :params do
          tmp = default_params.clone
          tmp.delete(:properties)
          tmp
        end
        it { expect { is_expected.to compile }.to raise_error(/must contain at least one entry/) }
      end

      context 'not a hash' do
        let :params do
          default_params.merge(:properties => ['this', 'is', 'not', 'a', 'hash'])
        end
        it { expect { is_expected.to compile }.to raise_error(/must be a Hash of values/) }
      end
    end
  end

  describe 'creates the file' do

    let :params do
      default_params
    end

    context 'mode' do
      it { is_expected.to contain_file('/opt/aem/crx-quickstart/install/aem.config').with_mode('0664') }
    end

    context 'group' do
      context 'default' do
        it { is_expected.to contain_file('/opt/aem/crx-quickstart/install/aem.config').with_group('aem') }
      end

      context 'specified group' do
        let :params do
          default_params.merge(:group => 'vagrant')
        end
        it { is_expected.to contain_file('/opt/aem/crx-quickstart/install/aem.config').with_group('vagrant') }
      end
    end

    context 'user' do
      context 'default' do
        it { is_expected.to contain_file('/opt/aem/crx-quickstart/install/aem.config').with_owner('aem') }
      end

      context 'specified owner' do
        let :params do
          default_params.merge(:user => 'vagrant')
        end
        it { is_expected.to contain_file('/opt/aem/crx-quickstart/install/aem.config').with_owner('vagrant') }
      end
    end

    context 'boolean property' do
      it do
        is_expected.to contain_file(
          '/opt/aem/crx-quickstart/install/aem.config'
        ).with_content(
          /boolean=B"false"\s/
        )
      end
    end

    context 'long property' do

      it do
        is_expected.to contain_file(
          '/opt/aem/crx-quickstart/install/aem.config'
        ).with_content(
          /long=L"123456789"\s/
        )
      end
    end

    context 'string property' do

      it do
        is_expected.to contain_file(
          '/opt/aem/crx-quickstart/install/aem.config'
        ).with_content(
          /string="string"\s/
        )
      end
    end

    context 'array property' do

      it do
        is_expected.to contain_file(
          '/opt/aem/crx-quickstart/install/aem.config'
        ).with_content(
          /array=\["an","array","of","values"\]/
        )
      end
    end

  end

  describe 'requires home directory' do
    let(:pre_condition) { 'file { "/opt/aem" : }' }

    let :params do
      default_params
    end

    context 'default' do
      it { is_expected.to contain_file('/opt/aem/crx-quickstart/install/aem.config').that_requires('File[/opt/aem]') }
    end

  end

end
