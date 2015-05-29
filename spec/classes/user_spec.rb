require 'spec_helper'

describe 'adobe_experience_manager' do
  let :facts do
    {
      :osfamily                 => 'RedHat',
      :operatingsystem          => 'CentOS',
      :operatingsystemrelease   => '7.0',
      :java_major_version       => '1.7',
    }
  end
  let :params do
    {
      :jar      => '/opt/aem/cq-author-4502.jar',
      :version  => '6.0',
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
  end
  
  context 'not managing user' do
    let :params do
      {
        :manage_user  => false,
        :jar          => '/opt/aem/cq-author-4502.jar',
        :version      => '6.0',
      }
    end
    it { is_expected.not_to contain_user('aem') }
  end

  context 'not managing group' do
    let :params do
      {
        :manage_group => false,
        :jar          => '/opt/aem/cq-author-4502.jar',
        :version      => '6.0',
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