require 'spec_helper'
describe 'adobe_experience_manager' do

  context 'with defaults for all parameters' do
    it { is_expected.to contain_class('adobe_experience_manager').with(
      'aem_home' => '/opt/aem',
      'jar'      => '/opt/aem/cq-author-4502.jar',
      'user'     => 'aem',
      'group'    => 'aem',
      'runmodes' => ['author']
      )
    }
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
        :manage_user => false
      }
    end
    it { is_expected.not_to contain_user('aem') }
  end
  context 'not managing group' do
    let :params do
      {
        :manage_group => false
      }
    end
    it { is_expected.not_to contain_group('aem') }
  end
  context 'invalid manage user' do
    let :params do
      {
        :manage_user => 'foo'
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
        :manage_group => 'foo'
      }
    end
    it do
      expect {
        catalogue
      }.to raise_error(Puppet::Error, /is not a boolean/)
    end
  end

end
