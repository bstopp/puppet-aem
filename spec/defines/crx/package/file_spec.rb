require 'spec_helper'

# Tests for the env script management based on parameters
describe 'aem::crx::package::file', type: :defines do

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
      source: '/path/to/file.zip',
      user: 'aem'
    }
  end

  let(:inst_dir) { '/opt/aem/crx-quickstart/install' }

  describe 'creates the file' do
    let(:params) { default_params }

    context 'mode' do
      it { is_expected.to contain_file("#{inst_dir}/file.zip").with_mode('0664') }
    end

    context 'group' do
      context 'default' do
        it { is_expected.to contain_file("#{inst_dir}/file.zip").with_group('aem') }
      end

      context 'specified group' do
        let(:params) do
          default_params.merge(group: 'vagrant')
        end
        it { is_expected.to contain_file("#{inst_dir}/file.zip").with_group('vagrant') }
      end
    end

    context 'user' do
      context 'default' do
        it { is_expected.to contain_file("#{inst_dir}/file.zip").with_owner('aem') }
      end

      context 'specified user' do
        let(:params) do
          default_params.merge(user: 'vagrant')
        end
        it { is_expected.to contain_file("#{inst_dir}/file.zip").with_owner('vagrant') }
      end
    end

    context 'source' do
      it { is_expected.to contain_file("#{inst_dir}/file.zip").with_source('/path/to/file.zip') }
    end
  end

  describe 'requires home directory' do
    let(:pre_condition) { 'file { "/opt/aem" : }' }

    let(:params) do
      default_params
    end

    context 'default' do
      it { is_expected.to contain_file("#{inst_dir}/file.zip").that_requires('File[/opt/aem]') }
    end
  end

end
