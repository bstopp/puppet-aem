require 'spec_helper'

describe 'adobe_experience_manager' do
  let :facts do
    {
      :osfamily => 'RedHat',
      :operatingsystem => 'CentOS',
      :operatingsystemrelease => '7.0',
    } 
  end
  
  let :params do 
    {
      'jar'       => '/opt/aem/cq-author-4502.jar',
    }
  end
  
  context 'default manage user/group' do
  
    it { is_expected.to contain_group('aem').with(
      'ensure' => 'present',
      )
    }
    it { is_expected.to contain_user('aem').with(
      'ensure'  => 'present',
      'gid'     => 'aem',
      )
    }

    it { is_expected.to contain_file('/opt/aem').with(
      'ensure' => 'directory',
      'owner' => 'aem',
      'group' => 'aem',
      )
    }
  end
  
  context 'not managing user' do
    let :params do
      {
        :manage_user => false,
      }
    end
    it { is_expected.not_to contain_user('aem') }
  end
  context 'not managing group' do
    let :params do
      {
        :manage_group => false,
      }
    end
    it { is_expected.not_to contain_group('aem') }
  end
  context 'invalid manage user' do
    let :params do
      {
        :manage_user => 'foo',
      }
    end
    it do
      expect {
        catalogue
      }.to raise_error(Puppet::Error, /is not a boolean/)
    end
  end
  context 'invalid manage group' do
    let :params do
      {
        :manage_group => 'foo',
      }
    end
    it do
      expect {
        catalogue
      }.to raise_error(Puppet::Error, /is not a boolean/)
    end
  end
  
end