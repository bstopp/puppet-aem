require 'beaker'
require 'beaker-rspec'
require 'beaker/puppet_install_helper'

puppet_version = ENV['PUPPET_VERSION'] || '4.2'

pkg_cmd = 'rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm'

module_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

master = only_host_with_role(hosts, 'master')
on master, "echo '#{master[:ip]} #{master}' >> /etc/hosts"
hosts_with_role(hosts, 'agent').each do |agent|
  on master, "echo '#{agent}' >> /etc/puppetlabs/puppet/autosign.conf"
  on master, "echo '#{agent}' >> /etc/puppetlabs/puppet/autosign.conf"
  on agent, "echo '#{master[:ip]} #{master}' >> /etc/hosts"
  on agent, "echo '#{agent[:ip]} #{agent}' >> /etc/hosts"
end

#aem_installer = File.expand_path(File.join(module_root, 'files', 'aem-quickstart.jar'))
unless ENV['BEAKER_provision'] == "no"

  hosts.each do |host|

    if host['roles'].include?('master')
      #Install Master

      master = host
      on master, pkg_cmd, { :acceptable_exit_codes => [0,1] }
      on master, "yum -y install puppet", { :acceptable_exit_code => [0,1] }

      config = {
        'main' => {
        'server'   => "#{master}",
        'certname' => "#{master}",
        'logdir'   => '/var/log/puppet',
        'vardir'   => '/var/lib/puppet',
        'ssldir'   => '/var/lib/puppet/ssl',
        'rundir'   => '/var/run/puppet',
        #'log_level' => 'debug'
        },
        'master' => {

        },
        'agent' => {
        'environment' => 'production'
        }
      }

      on master, "yum -y install puppetserver", { :acceptable_exit_codes => [0,1] }

      configure_puppet_on(master, config)

      on master, puppet('resource', 'package', 'puppetserver', 'ensure=latest'), { :acceptable_exit_codes => [0,1] }
      on master, puppet('resource', 'service', 'puppetserver', 'ensure=running', 'enable=true'), { :acceptable_exit_codes => [0,1] }

      on master, puppet('module', 'install', 'puppetlabs-stdlib'), { :acceptable_exit_codes => [0,1] }
      on master, puppet('module', 'install', 'puppetlabs-java'), { :acceptable_exit_codes => [0,1] }

    else
      #Install agent.
      agent = host

      on agent, pkg_cmd, { :acceptable_exit_codes => [0,1] }
      on agent, "yum -y install puppet"

      master_fqdn= "#{master}"
      agent_fqdn = "#{agent}"

      config = {
        'main' => {
        'server'   => master_fqdn,
        'certname' => agent_fqdn,
        'logdir'   => '/var/log/puppet',
        'vardir'   => '/var/lib/puppet',
        'ssldir'   => '/var/lib/puppet/ssl',
        'rundir'   => '/var/run/puppet',
        'certificate_revocation' => false,
        #'log_level' => 'debug'
        },
        'agent' => {
        'server'   => master_fqdn,
        'certname' => agent_fqdn,
        'environment' => 'production'
        }
      }
      configure_puppet_on(agent, config)

      #manifest = "class { 'java' : }"
      #apply_manifest_on(agent, manifest)
      puppetdef = "service { 'puppet': ensure => stopped }"
      apply_manifest_on(agent, puppetdef)

      puppetdef = "service { 'puppet': ensure => running }"
      apply_manifest_on(agent, puppetdef)

      aem_installer = File.expand_path(File.join(module_root, 'files', 'aem-quickstart.jar'))

      scp_to(agent, aem_installer, '/tmp/aem-quickstart.jar')

    end

    on host, puppet('service', 'firewalld', 'ensure=stopped', 'enable=false'), { :acceptable_exit_codes => [0,1] }
    on host, "iptables -F"

  end
end


puppet_module_install_on(master, {
  :target_module_path => '/etc/puppetlabs/code/environments/production/modules', 
  :source => module_root, 
  :module_name => 'aem' 
})

RSpec.configure do |c|

  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do

  end
end