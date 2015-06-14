require 'beaker-rspec'

unless ENV['RS_PROVISION'] == 'no'
  
  hosts.each do |host|
    # Install Puppet
    on host, install_puppet
  end
end


UNSUPPORTED_PLATFORMS = ['Suse','windows','AIX','Solaris']

RSpec.configure do |c|
  module_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  aem_installer = File.expand_path(File.join(module_root, 'files', 'aem-quickstart-4502.jar'))
  
  scp_to hosts, aem_installer, '/var/aem-quickstart-4502.jar'
  
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do

    puppet_module_install(:source => module_root, :module_name => 'aem-module')
    
    # Install module
    hosts.each do |host|
      on host, puppet('module', 'install', 'puppetlabs-stdlib'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'puppetlabs-java'), { :acceptable_exit_codes => [0,1] }
      
      manifest = "class { 'java' : }"
      apply_manifest_on(host, manifest)
      
    end
  end
end