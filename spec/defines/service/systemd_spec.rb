# frozen_string_literal: true

require 'spec_helper'

# Tests for the env script management based on parameters
describe 'aem::service::systemd' do

  let(:facts) do
    {
      kernel: 'Linux',
      operatingsystem: 'CentOS',
      osfamily: 'RedHat',
      operatingsystemmajrelease: '7'
    }
  end

  let(:title) do
    'aem'
  end

  let(:default_params) do
    {
      ensure: 'present',
      status: 'enabled',
      home: '/opt/aem',
      user: 'aem',
      group: 'aem',
      service_options: { 'TimeoutStopSec' => '4min', 'KillSignal' => 'SIGCONT', 'PrivateTmp' => true }
    }
  end

  context 'Setup service' do
    let(:params) do
      default_params
    end
    it { should contain_aem__service__systemd('aem') }
    it { should contain_exec('reload_systemd_aem_aem').with(command: '/bin/systemctl daemon-reload') }
    it { should contain_service('aem-aem').with(ensure: 'running', enable: true, provider: 'systemd') }

  end

  context 'Remove service' do
    let(:params) do
      default_params
    end
    it { should contain_aem__service__systemd('aem') }
    it { should contain_exec('reload_systemd_aem_aem').with(command: '/bin/systemctl daemon-reload') }
    it { should contain_service('aem-aem').with(ensure: 'running', enable: true, provider: 'systemd') }

  end

  describe 'aem-author.service file' do
    context 'default contents' do
      let(:params) do
        default_params
      end
      it do
        is_expected.to contain_file(
          '/lib/systemd/system/aem-aem.service'
        ).with_content(
          /PIDFile=\/opt\/aem\/crx-quickstart\/conf\/cq.pid/
        )
      end
      it do
        is_expected.to contain_file(
           '/lib/systemd/system/aem-aem.service'
        ).with_content(
          /User=aem/
        )
      end
      it do
        is_expected.to contain_file(
           '/lib/systemd/system/aem-aem.service'
        ).with_content(
          /Group=aem/
        )
      end
      it do
        is_expected.to contain_file(
           '/lib/systemd/system/aem-aem.service'
        ).with_content(
          /ExecStart=\/opt\/aem\/crx-quickstart\/bin\/start/
        )
      end
      it do
        is_expected.to contain_file(
           '/lib/systemd/system/aem-aem.service'
        ).with_content(
          /ExecStop=\/opt\/aem\/crx-quickstart\/bin\/stop/
        )
      end
      it do
        is_expected.to contain_file(
           '/lib/systemd/system/aem-aem.service'
        ).with_content(
          /TimeoutStopSec=4min/
        )
      end
      it do
        is_expected.to contain_file(
           '/lib/systemd/system/aem-aem.service'
        ).with_content(
          /KillSignal=SIGCONT/
        )
      end
      it do
        is_expected.to contain_file(
           '/lib/systemd/system/aem-aem.service'
        ).with_content(
          /PrivateTmp=true/
        )
      end
    end

    context 'custom properties' do
      let(:params) do
        {
            ensure: 'present',
            status: 'enabled',
            home: '/opt/aem',
            user: 'aem',
            group: 'aem',
            service_options: {
                'TimeoutStopSec' => '10min',
                'KillSignal' => 'SIGKILL',
                'PrivateTmp' => true
            }
        }
      end
     it do
        is_expected.to contain_file(
           '/lib/systemd/system/aem-aem.service'
        ).with_content(
          /TimeoutStopSec=10min/
        )
      end
      it do
        is_expected.to contain_file(
           '/lib/systemd/system/aem-aem.service'
        ).with_content(
          /KillSignal=SIGKILL/
        )
      end
      it do
        is_expected.to contain_file(
           '/lib/systemd/system/aem-aem.service'
        ).with_content(
          /PrivateTmp=true/
        )
      end
    end
  end

end
