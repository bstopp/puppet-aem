require 'spec_helper'

# Tests for the env script management based on parameters
describe 'aem::osgi::config::file', type: :defines do

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
      ensure: 'present',
      group: 'aem',
      home: '/opt/aem',
      pid: :undef,
      properties: {
        'boolean' => false,
        'long'    => 123_456_789,
        'string'  => 'string',
        'array'   => ['an', 'array', 'of', 'values']
      },
      user: 'aem'
    }
  end

  describe 'creates the file' do

    let(:params) do
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
        let(:params) do
          default_params.merge(group: 'vagrant')
        end
        it { is_expected.to contain_file('/opt/aem/crx-quickstart/install/aem.config').with_group('vagrant') }
      end
    end

    context 'user' do
      context 'default' do
        it { is_expected.to contain_file('/opt/aem/crx-quickstart/install/aem.config').with_owner('aem') }
      end

      context 'specified owner' do
        let(:params) do
          default_params.merge(user: 'vagrant')
        end
        it { is_expected.to contain_file('/opt/aem/crx-quickstart/install/aem.config').with_owner('vagrant') }
      end
    end

    context 'service pid' do
      it do
        is_expected.to contain_file(
          '/opt/aem/crx-quickstart/install/aem.config'
        ).with_content(
          /service.pid="aem"\s/
        )
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

    let(:params) do
      default_params
    end

    context 'default' do
      it { is_expected.to contain_file('/opt/aem/crx-quickstart/install/aem.config').that_requires('File[/opt/aem]') }
    end
  end

  describe 'uses pid for file name' do
    let(:pre_condition) { 'file { "/opt/aem" : }' }

    let(:params) do
      default_params.merge(pid: 'aem.osgi')
    end

    context 'default' do
      it do
        is_expected.to contain_file(
          '/opt/aem/crx-quickstart/install/aem.osgi.config'
        ).that_requires(
          'File[/opt/aem]'
        )
      end
    end

  end

end
