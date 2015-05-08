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

  context 'defaults for all parameters; invalid port' do
    let :params do 
      {
        :jar              => '/opt/aem/cq-author-4502.jar',
        :version          => '6.0',
        :port             => 'foo',
      }
    end
    
    it do
      expect {
        catalogue
      }.to raise_error(Puppet::Error, /not an integer/)
    end
  end

  context 'defaults for all parameters; port 4502' do
    let :params do 
      {
        :jar              => '/opt/aem/cq-author-4502.jar',
        :version          => '6.0',
        :port             => 4502,
      }
    end
    
    it { is_expected.to contain_class('adobe_experience_manager').with({ :port => 4502}) }
  end

  context 'defaults for all parameters; invalid log_level' do
    let :params do 
      {
        :jar              => '/opt/aem/cq-author-4502.jar',
        :version          => '6.0',
        :log_level        => 'foo',
      }
    end
    
    it do
      expect {
        catalogue
      }.to raise_error(Puppet::Error, /not an integer/)
    end
  end

  context 'defaults for all parameters; log_level 3' do
    let :params do 
      {
        :jar              => '/opt/aem/cq-author-4502.jar',
        :version          => '6.0',
        :log_level        => 3,
      }
    end
    
    it { is_expected.to contain_class('adobe_experience_manager').with({ :log_level => 3}) }
  end

  context 'defaults for all parameters; invalid jvm_opts' do
    let :params do 
      {
        :jar              => '/opt/aem/cq-author-4502.jar',
        :version          => '6.0',
        :jvm_opts         => false,
      }
    end
    
    it do
      expect {
        catalogue
      }.to raise_error(Puppet::Error, /not a string/)
    end
  end

  context 'defaults for all parameters; jvm_opts specified' do
    let :params do 
      {
        :jar              => '/opt/aem/cq-author-4502.jar',
        :version          => '6.0',
        :jvm_opts         => '-Xmx2048m',
      }
    end
    
    it { is_expected.to contain_class('adobe_experience_manager').with({ :jvm_opts => '-Xmx2048m'}) }
  end

  context 'defaults for all parameters; invalid mongo' do
    let :params do 
      {
        :jar              => '/opt/aem/cq-author-4502.jar',
        :version          => '6.0',
        :mongo            => 'foo',
      }
    end
    
    it do
      expect {
        catalogue
      }.to raise_error(Puppet::Error, /not a boolean/)
    end
  end

  context 'defaults for all parameters; mongo true' do
    let :params do 
      {
        :jar              => '/opt/aem/cq-author-4502.jar',
        :version          => '6.0',
        :mongo            => true,
      }
    end
    
    it { is_expected.to contain_class('adobe_experience_manager').with({ :mongo => true}) }
  end

    context 'defaults for all parameters; invalid jvm_opts' do
    let :params do 
      {
        :jar              => '/opt/aem/cq-author-4502.jar',
        :version          => '6.0',
        :mongo_uri        => false,
      }
    end
    
    it do
      expect {
        catalogue
      }.to raise_error(Puppet::Error, /not a string/)
    end
  end

  context 'defaults for all parameters; jvm_opts specified' do
    let :params do 
      {
        :jar              => '/opt/aem/cq-author-4502.jar',
        :version          => '6.0',
        :mongo_uri         => 'mongodb://127.0.0.1:27017',
      }
    end
    
    it { is_expected.to contain_class('adobe_experience_manager').with({ :mongo_uri => 'mongodb://127.0.0.1:27017a'}) }
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
