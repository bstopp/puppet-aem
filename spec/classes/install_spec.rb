require 'spec_helper'

describe 'adobe_experience_manager' do
  let :facts do
    {
      :osfamily => 'RedHat',
      :operatingsystem => 'CentOS',
      :operatingsystemrelease => '7.0',
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

end