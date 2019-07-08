# frozen_string_literal: true

require 'beaker'
require 'beaker-rspec'
require 'beaker/puppet_install_helper'
require 'puppet'

def fqdn(host)
  on(host, 'facter fqdn').stdout.strip
end

def setup_agents(version)
  step 'Agents' do
    # Install the Puppet Agent on all hosts
    install_puppet_agent_on(hosts, version: version)
    case fact('osfamily')
    when 'RedHat'
      $log_root = '/var/log/httpd'
      $mod_root = '/etc/httpd/modules'
      $conf_dir = '/etc/httpd/conf.modules.d'
    when 'Debian'
      $log_root = '/var/log/apache2'
      $mod_root = '/usr/lib/apache2/modules'
      $conf_dir = '/etc/apache2/mods-enabled'
    end

  end
end

def install_modules
  step 'Modules' do
    module_root = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
    # Install all needed modules
    on master, puppet('module', 'install', 'puppetlabs-apache'), acceptable_exit_codes: [0, 1]
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

RSpec.configure do |c|

  puppet_version = ENV['PUPPET_VERSION'] || raise('Unspecified Puppet Version.')

  c.formatter = :documentation
  c.fail_if_no_examples = true
  c.before :suite do
    $debug = ENV['BEAKER_debug'] ? '--debug' : ''
    setup_agents(puppet_version)
    $master_fqdn = fqdn(master)
    prepare_master
  end
end

describe 'dispatcher' do
  context 'install' do
    context 'run' do
      it 'should work' do
        step 'Install Dispatcher' do
          step 'Setup' do
            pp = <<~MANIFEST
              file {
                '#{master.puppet['codedir']}/environments/production/manifests/site.pp':
                  ensure => file,
                  source => '/vagrant/puppet/files/manifests/dispatcher_setup.pp'
              }
            MANIFEST
            apply_manifest_on(master, pp, catch_failures: true)

          end

          with_puppet_running_on(master, {}, '/tmp') do

            step 'Run agent' do
              on(default, puppet("agent -t #{$debug} --server #{$master_fqdn}"), acceptable_exit_codes: [0, 2])

              on(default, puppet("agent -t #{$debug} --server #{$master_fqdn}"), acceptable_exit_codes: [0])
            end
          end

          cmd = "grep -- 'Communique/.* configured -- resuming normal operations' #{$log_root}/error*"
          on(default, cmd) do |result|
            assert_equal(0, result.exit_code)
          end
        end
      end
    end
    context 'log file' do
      it 'should have no errors in log' do
        on(default, "test -f #{$log_root}/dispatcher.log") do |result|
          assert_equal(0, result.exit_code)
        end
        on(default, "stat --printf=%s #{$log_root}/dispatcher.log") do |result|
          assert_equal(0, result.stdout.to_i)
        end
      end
    end
    context 'module file' do
      it 'should have copied the dispatcher module file' do
        on(default, "test -f #{$mod_root}/dispatcher-apache-module.so") do |result|
          assert_equal(0, result.exit_code)
        end
      end

      it 'should be owned by specified user/group' do
        on(default, "stat -c \"%U:%G\" #{$mod_root}/dispatcher-apache-module.so") do |result|
          assert_equal('root:root', result.stdout.strip)
        end
      end

      it 'should have been created' do
        on(default, "test -f #{$mod_root}/mod_dispatcher.so") do |result|
          assert_equal(0, result.exit_code)
        end
      end

      it 'should be a symbolic link' do
        on(default, "stat -c \"%F\" #{$mod_root}/mod_dispatcher.so") do |result|
          assert_equal('symbolic link', result.stdout.strip)
        end
      end
    end
  end

  context 'remove' do
    context 'run' do
      it 'should work' do
        step 'Remove Dispatcher' do
          step 'Setup' do
            pp = <<~MANIFEST
              file {
                '#{master.puppet['codedir']}/environments/production/manifests/site.pp':
                  ensure => file,
                  source => '/vagrant/puppet/files/manifests/dispatcher_absent.pp'
              }
            MANIFEST
            apply_manifest_on(master, pp, catch_failures: true)
          end

          with_puppet_running_on(master, {}, '/tmp') do

            step 'Run agent' do
              on(default, puppet("agent -t #{$debug} --server #{$master_fqdn}"), acceptable_exit_codes: [0, 2])

              on(default, puppet("agent -t #{$debug} --server #{$master_fqdn}"), acceptable_exit_codes: [0])
            end
          end
        end
      end
    end
    context 'module file' do
      it 'should have removed sym link' do
        on(default, "test -f #{$mod_root}/mod_dispatcher.so", accept_all_exit_codes: true) do |result|
          assert(result.exit_code != 0)
        end
      end
      it 'should have removed module file' do
        on(default, "test -f #{$mod_root}/dispatcher-apache-module.so", accept_all_exit_codes: true) do |result|
          assert(result.exit_code != 0)
        end
      end
      it 'should have removed conf file' do
        on(default, "test -f #{$conf_dir}/dispatcher.conf", accept_all_exit_codes: true) do |result|
          assert(result.exit_code != 0)
        end
      end
    end
  end
end
