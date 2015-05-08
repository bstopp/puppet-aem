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
  
  context 'with defaults for all parameters' do
    it do
      expect {
        catalogue
      }.to raise_error(Puppet::Error, /Installer jar required but not defined/)
    end
  end
  
  context 'required jar but not version and defaults for all other parameters' do
    let :params do 
      {
        :jar       => '/opt/aem/cq-author-4502.jar',
      }
    end
    
    it do
      expect {
        catalogue
      }.to raise_error(Puppet::Error, /Version of AEM is not defined./)
    end
  end

  context 'defaults for all parameters; invalid includesamples' do
    let :params do 
      {
        :jar              => '/opt/aem/cq-author-4502.jar',
        :version          => '6.0',
        :includesamples   => 'foo',
      }
    end
    
    it do
      expect {
        catalogue
      }.to raise_error(Puppet::Error, /not a boolean/)
    end
  end

  context 'defaults for all parameters; includesamples false' do
    let :params do 
      {
        :jar              => '/opt/aem/cq-author-4502.jar',
        :version          => '6.0',
        :includesamples   => false,
      }
    end
    
    it { is_expected.to contain_class('adobe_experience_manager').with({ :includesamples => false}) }
  end

  context 'required jar and version and defaults for all other parameters' do
    let :params do
      {
        :jar       => '/opt/aem/cq-author-4502.jar',
        :version   => '6.0',
      }
    end
    
    it { is_expected.to contain_class('adobe_experience_manager').with(
        :aem_home           => '/opt/aem',
        :jar                => '/opt/aem/cq-author-4502.jar',
        :user               => 'aem',
        :group              => 'aem',
        :runmodes           => ['author'],
        :includesamples     => true,
        :mongo              => false,
      )
    }
    it { is_expected.to contain_class('adobe_experience_manager::user') }
    it { is_expected.to contain_class('adobe_experience_manager::config').that_requires('adobe_experience_manager::user') }
    it { is_expected.to contain_class('adobe_experience_manager::config').that_notifies('adobe_experience_manager::service') }
    it { is_expected.to contain_class('adobe_experience_manager::install').that_requires('adobe_experience_manager::config') }
    it { is_expected.to contain_class('adobe_experience_manager::install').that_notifies('adobe_experience_manager::service') }
    it { is_expected.to contain_class('adobe_experience_manager::service') }

  end
  
end
