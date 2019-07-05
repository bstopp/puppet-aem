# frozen_string_literal: true

require 'beaker'
require 'beaker-rspec'
require 'beaker/puppet_install_helper'
require 'erb'
require 'puppet'

def fqdn(host)
  on(host, 'facter fqdn').stdout.strip
end

def setup_template
  module_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
  license = ENV['AEM_LICENSE'] || 'fake-key-for-testing'
  tpl = File.read(File.join(module_root, 'spec', 'acceptance', 'files', 'templates', 'aem', 'setup.pp.erb'))
  erb = ERB.new(tpl)
  erb.result(binding)
end

def setup_agents(version)
  step 'Agents' do
    # Install the Puppet Agent on all hosts
    install_puppet_agent_on(hosts, version: version)
  end
end

def install_modules
  step 'Modules' do
    module_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
    # Install all needed modules
    on master, puppet('module', 'install', 'puppetlabs-ruby'), acceptable_exit_codes: [0, 1]
    on master, puppet('module', 'install', 'puppetlabs-stdlib'), acceptable_exit_codes: [0, 1]
    on master, puppet('module', 'install', 'puppetlabs-concat'), acceptable_exit_codes: [0, 1]
    on master, puppet('module', 'install', 'puppetlabs-apache'), acceptable_exit_codes: [0, 1]
    on master, puppet('module', 'install', 'puppetlabs-java'), acceptable_exit_codes: [0, 1]
    # Copy over dev module
    install_dev_puppet_module_on(master, source: module_root, module_name: 'aem')
  end
end

def install_puppetserver
  step 'Server' do

    # Setup Puppet Server on Master
    master.install_package('puppetserver')
    master['puppetserver-confdir'] = '/etc/puppetlabs/puppetserver/conf.d'
    master['puppetservice'] = 'puppetserver'
    master['use-service'] = true
    master.options[:is_puppetserver] = true
  end
end

def configure_puppetserver

  step 'Autosign Agent' do
    agenthostname = on(default, 'facter fqdn').stdout.strip
    pp = "file { '#{master.puppet['confdir']}/autosign.conf': ensure => file, content => '#{agenthostname}' }"
    apply_manifest_on(master, pp)
  end
end

def prepare_master
  step 'Master' do
    install_modules
    install_puppetserver
    configure_puppetserver
  end
end

def install_aem
  step 'Install AEM' do
    step 'Setup' do

      pp = <<~MANIFEST
        file {
          '#{master.puppet['codedir']}/environments/production/manifests/site.pp':
            ensure => file,
            content => "#{setup_template}"
        }
      MANIFEST
      apply_manifest_on(master, pp, catch_failures: true)
    end
    step 'Run agent' do
      with_puppet_running_on(master, {}, '/tmp') do

        on(default, puppet("agent -t #{$debug} --server #{$master_fqdn}"), acceptable_exit_codes: [0, 2])

        on(default, puppet("agent -t #{$debug} --server #{$master_fqdn}"), acceptable_exit_codes: [0])
      end
    end
  end
end

def prepare_agent
  install_aem
end

RSpec.configure do |c|

  puppet_version = ENV['PUPPET_VERSION'] || raise('Unspecified Puppet Version.')

  c.filter_run_excluding(license: false) unless ENV['AEM_LICENSE']
  c.formatter = :documentation

  c.before :suite do
    $debug = ENV['BEAKER_debug'] ? '--debug' : ''
    setup_agents(puppet_version)
    $master_fqdn = fqdn(master)
    prepare_master
    prepare_agent
  end

  c.after :suite do
    step 'Teardown' do
      step 'Remove AEM' do
        on(default, "puppet resource service aem-author ensure=stopped")
        on(default, "rm -Rf /opt/aem")
      end
    end
  end
end
