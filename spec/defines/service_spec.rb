require 'spec_helper'

# Tests for the env script management based on parameters
describe 'aem::service', type: :defines do

  let(:title) do
    'aem'
  end

  let(:default_facts) do
    {
      kernel: 'Linux'
    }
  end

  let(:default_params) do
    {
      home: '/opt/aem'
    }
  end

  describe 'parameter validation' do
    context 'home' do
      context 'not specified' do
        let(:params) do
          tmp = default_params.clone
          tmp.delete(:home)
          tmp
        end
        it { expect { is_expected.to compile }.to raise_error(/Home directory must be specified./) }
      end

      context 'not absolute' do
        let(:params) do
          default_params.merge(home: 'not/absolute/path')
        end
        it { expect { is_expected.to compile }.to raise_error(/is not an absolute path/) }
      end
    end
  end

  %w[CentOS Fedora RedHat].each do |os|
    context os do

      let(:params) do
        default_params
      end

      context 'version >= 7' do
        let(:facts) do
          default_facts.merge(operatingsystem: os, operatingsystemmajrelease: '7')
        end
        it do
          is_expected.to contain_aem__service__systemd('aem').only_with(
            ensure: 'present',
            name: 'aem',
            status: 'enabled',
            group: 'aem',
            home: '/opt/aem',
            user: 'aem'
          )
        end
      end

      context 'version < 7' do
        let(:facts) do
          default_facts.merge(operatingsystem: os, operatingsystemmajrelease: '6')
        end
        it do
          is_expected.to contain_aem__service__init('aem').only_with(
            ensure: 'present',
            name: 'aem',
            status: 'enabled',
            group: 'aem',
            home: '/opt/aem',
            user: 'aem'
          )
        end
      end
    end
  end

  describe 'Amazon' do

    context 'version >= 2' do

      let(:facts) do
        default_facts.merge(operatingsystem: 'Amazon', operatingsystemmajrelease: '2')
      end

      let(:params) do
        default_params
      end

      it do
        is_expected.to contain_aem__service__systemd('aem').only_with(
            ensure: 'present',
            name: 'aem',
            status: 'enabled',
            group: 'aem',
            home: '/opt/aem',
            user: 'aem'
        )
      end
    end

    context 'version < 2' do

      let(:facts) do
        default_facts.merge(operatingsystem: 'Amazon', operatingsystemmajrelease: '2016')
      end

      let(:params) do
        default_params
      end

      it do
        is_expected.to contain_aem__service__init('aem').only_with(
          ensure: 'present',
          name: 'aem',
          status: 'enabled',
          group: 'aem',
          home: '/opt/aem',
          user: 'aem'
        )
      end
    end

  end

  describe 'Debian' do
    context 'version >= 8' do

      let(:facts) do
        default_facts.merge(operatingsystem: 'Debian', operatingsystemmajrelease: '8')
      end

      let(:params) do
        default_params
      end

      it do
        is_expected.to contain_aem__service__systemd('aem').only_with(
          ensure: 'present',
          name: 'aem',
          status: 'enabled',
          group: 'aem',
          home: '/opt/aem',
          user: 'aem'
        )
      end
    end

    context 'version < 7' do
      let(:facts) do
        default_facts.merge(operatingsystem: 'Debian', operatingsystemmajrelease: '7')
      end

      let(:params) do
        default_params
      end

      it do
        is_expected.to contain_aem__service__init('aem').only_with(
          ensure: 'present',
          name: 'aem',
          status: 'enabled',
          group: 'aem',
          home: '/opt/aem',
          user: 'aem'
        )
      end

    end
  end

  describe 'Ubuntu' do
    context 'version >= 15' do

      let(:facts) do
        default_facts.merge(operatingsystem: 'Ubuntu', operatingsystemmajrelease: '15')
      end

      let(:params) do
        default_params
      end

      it do
        is_expected.to contain_aem__service__systemd('aem').only_with(
          ensure: 'present',
          name: 'aem',
          status: 'enabled',
          group: 'aem',
          home: '/opt/aem',
          user: 'aem'
        )
      end
    end

    context 'version < 7' do
      let(:facts) do
        default_facts.merge(operatingsystem: 'Ubuntu', operatingsystemmajrelease: '14')
      end

      let(:params) do
        default_params
      end

      it do
        is_expected.to contain_aem__service__init('aem').only_with(
          ensure: 'present',
          name: 'aem',
          status: 'enabled',
          group: 'aem',
          home: '/opt/aem',
          user: 'aem'
        )
      end

    end
  end
end
