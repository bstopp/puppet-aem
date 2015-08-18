require 'beaker'
require 'beaker-rspec'
require 'beaker/puppet_install_helper'

run_puppet_install_helper

UNSUPPORTED_PLATFORMS = ['Suse','windows','AIX','Solaris']

RSpec.configure do |c|
  module_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  aem_installer = File.expand_path(File.join(module_root, 'files', 'aem-quickstart.jar'))

  scp_to(hosts, aem_installer, 
    '/tmp/aem-quickstart.jar') unless ENV["RS_PROVISION="] == "no" or ENV["BEAKER_provision"] == "no"

  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do

    puppet_module_install(:source => module_root, :module_name => 'aem')
    
    # Install module
    hosts.each do |host|

      on host, puppet('module', 'install', 'puppetlabs-stdlib'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'puppetlabs-java'), { :acceptable_exit_codes => [0,1] }

      manifest = "class { 'java' : }"
      apply_manifest_on(host, manifest)

      # Make sure selinux is disabled before each test or apache won't work.
      if ! UNSUPPORTED_PLATFORMS.include?(fact('osfamily'))
        on host, puppet('apply', '-e',
                          %{"exec { 'setenforce 0': path   => '/bin:/sbin:/usr/bin:/usr/sbin', onlyif => 'which setenforce && getenforce | grep Enforcing', }"}),
                          { :acceptable_exit_codes => [0] }
      end

    end
  end
end