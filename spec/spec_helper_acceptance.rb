require 'beaker'
require 'beaker-rspec'
require 'beaker/puppet_install_helper'

UNSUPPORTED_PLATFORMS = ['Suse','windows','AIX','Solaris']
ENV['PUPPET_INSTALL_VERSION'] = ENV['PUPPET_INSTALL_VERSION'] || '4.2'

def server_opts
  { 
    :master => {:autosign => true}, 
  }
end

def stop_firewall_on(host)
  case host['platform']
  when /debian/
    on host, 'iptables -F'
  when /fedora|el-7/
    on host, puppet('resource', 'service', 'firewalld', 'ensure=stopped')
  when /el|centos/
    on host, puppet('resource', 'service', 'iptables', 'ensure=stopped')
  when /ubuntu/
    on host, puppet('resource', 'service', 'ufw', 'ensure=stopped')
  else
    logger.notify("Not sure how to clear firewall on #{host['platform']}")
  end
end

module_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

unless ENV['BEAKER_provision'] == 'no'

  aem_installer = File.expand_path(File.join(module_root, 'files', 'aem-quickstart.jar'))
  scp_to(hosts, aem_installer,
   '/tmp/aem-quickstart.jar') unless ENV["RS_PROVISION="] == "no" or ENV["BEAKER_provision"] == "no"

  # Credit to Puppetlabs Puppet Agent project,
  # This was the only place i could find that had an example that
  # made all of this stuff work.

  # Install puppet-server on master
  step "Setup Puppet"
  install_puppetlabs_release_repo master

  options['is_puppetserver'] = true
  master['puppetservice'] = 'puppetserver'
  master['puppetserver-confdir'] = '/etc/puppetlabs/puppetserver/conf.d'
  master['type'] = 'aio'
  install_puppet_agent_on master, {:puppet_agent_version => '1.2.2'}
  install_package master, 'puppetserver'
  master['use-service'] = true

  on master, puppet('module', 'install', 'puppetlabs-stdlib'), { :acceptable_exit_codes => [0,1] }
  on master, puppet('module', 'install', 'puppetlabs-java'), { :acceptable_exit_codes => [0,1] }

  manifest = "class { 'java' : }"
  apply_manifest_on(master, manifest)

  stop_firewall_on(master)

end

# Install module
install_dev_puppet_module_on(master, :source => module_root, :module_name => 'aem')

RSpec.configure do |c|
  c.formatter = :documentation
end