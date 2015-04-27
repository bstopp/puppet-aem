require 'spec_helper'

describe 'adobe_experience_manager' do
  let :facts do
    {
      :osfamily => 'RedHat',
      :operatingsystem => 'CentOS',
      :operatingsystemrelease => '7.0',
    } 
  end
  
  context 'with defaults for all parameters' do
    it do
      expect {
        catalogue
      }.to raise_error(Puppet::Error, /Installer jar required but not defined/)
    end
  end
  
  context 'required jar and defaults for all other parameters' do
    let :params do 
      {
        'jar'       => '/opt/aem/cq-author-4502.jar',
      }
    end
    
    it { is_expected.to contain_class('adobe_experience_manager').with(
      'aem_home'  => '/opt/aem',
      'jar'       => '/opt/aem/cq-author-4502.jar',
      'user'      => 'aem',
      'group'     => 'aem',
      'runmodes'  => ['author'],
      )
    }
    it { is_expected.to contain_class('adobe_experience_manager::user') }
    it { is_expected.to contain_class('adobe_experience_manager::config') }
    it { is_expected.to contain_class('adobe_experience_manager::install') }
    it { is_expected.to contain_class('adobe_experience_manager::service') }

  end
  
end
