require 'spec_helper'

# Tests for the env script management based on parameters
describe 'aem::service::systemd', :type => :defines do

  let :facts do
    {
      :kernel                     => 'Linux',
      :operatingsystem            => 'CentOS',
      :osfamily                   => 'RedHat',
      :operatingsystemmajrelease  => '7',
    }
  end

  let :title do
    'aem'
  end


  let :default_params do
    {
      :ensure => 'present',
      :status => 'enabled',
      :home   => '/opt/aem',
      :user   => 'aem',
      :group  => 'aem',
    }
  end

  context 'Setup service' do
    let :params do 
      default_params
    end
    it { should contain_aem__service__systemd('aem') }
    it { should contain_exec('reload_systemd_aem_aem').with(:command => '/bin/systemctl daemon-reload') }
    it { should contain_service('aem-aem').with(:ensure => 'running', :enable => true, :provider => 'systemd') }
      
  end

  context 'Remove service' do
    let :params do 
      default_params
    end
    it { should contain_aem__service__systemd('aem') }
    it { should contain_exec('reload_systemd_aem_aem').with(:command => '/bin/systemctl daemon-reload') }
    it { should contain_service('aem-aem').with(:ensure => 'running', :enable => true, :provider => 'systemd') }
      
  end

end