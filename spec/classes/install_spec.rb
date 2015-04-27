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
    }
  end

  
  context 'invalid aem home path' do
    let :params do
      {
        :aem_home => 'not/a/fully/qualified/path',
        :jar      => '/opt/aem/cq-author-4502.jar',
      }
    end
    it do
      expect {
        catalogue
      }.to raise_error(Puppet::Error, /absolute path/)
    end
  end
  
  context 'java not installed' do
    let :facts do 
      {
        :osfamily                 => 'RedHat',
        :operatingsystem          => 'CentOS',
        :operatingsystemrelease   => '7.0',
      } 
    end
    it do
      expect {
        catalogue
      }.to raise_error(Puppet::Error, /Java is required/)
    end
  end
        
  context 'AEM version not specified' do
    it { is_expected.to contain_class('adobe_experience_manager').with(
        'req_java_version'   => '.*',
      )
    }
  end
  
end
