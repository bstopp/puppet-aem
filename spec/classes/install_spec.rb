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
      :version   => '6.0',
    }
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
        
  context 'Java/AEM combo not supported' do
    let :facts do 
      {
        :osfamily                 => 'RedHat',
        :operatingsystem          => 'CentOS',
        :operatingsystemrelease   => '7.0',
        :java_major_version       => '1.8',
      } 
    end
    let :params do 
      {
        :jar       => '/opt/aem/cq-author-4502.jar',
        :version   => '6.0',
      }
    end
    it do
      expect {
        catalogue
      }.to raise_error(Puppet::Error, /version of Java is not supported/)
    end
  end
  
  context 'AEM 6.0/Java 1.7 Supported' do
    it { 
      is_expected.to contain_class('adobe_experience_manager::install').with(
        :cabfile  => "installed.cab",
        :runmodes  => ['author'],
        :mongo    => false,
      )
    }
  end
  
  context 'install.sh created' do
    it {
      is_expected.to contain_file('/opt/aem/install.sh').with_content(
        /java -jar \/opt\/aem\/cq-author-4502.jar -nobrowser -b \/opt\/aem -r author > \/dev\/null 2>&1 &/
      )
    }
  end
end
