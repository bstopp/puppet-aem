require 'spec_helper'
describe 'adobe_experience_manager' do

  context 'with defaults for all parameters' do
    it { is_expected.to contain_class('adobe_experience_manager') }
    it { is_expected.to contain_group('aem').with(
      ensure => 'present',
      )
    }
    it { is_expected.to contain_user('aem').with(
      ensure  => 'present',
      gid     => 'aem',
      )
    }

    it { is_expected.to contain_file('/opt/aem').with(
      'ensure' => 'directory',
      'owner' => 'aem',
      'group' => 'aem', 
      )
    }
  end
end
