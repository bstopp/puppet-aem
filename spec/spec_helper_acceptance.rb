require 'beaker'
require 'beaker-rspec'
require 'beaker/puppet_install_helper'

UNSUPPORTED_PLATFORMS = %w(Suse windows AIX Solaris).freeze
ENV['PUPPET_INSTALL_VERSION'] = ENV['PUPPET_INSTALL_VERSION'] || '4.2'

def server_opts
  {
    master: { autosign: true }
  }
end

def clear_ssl
  step 'Clear SSL on all hosts'
  hosts.each do |ahost|
    stop_firewall_on ahost
    ssldir = on(ahost, puppet('agent --configprint ssldir')).stdout.chomp
    on(ahost, "rm -rf #{ssldir}/*")
  end
end

def stop_firewall_on(host)
  case host['platform']
  when /debian/
    on host, 'iptables -F'
  when /fedora|el-7/
    on host, puppet('resource', 'service', 'firewalld', 'ensure=stopped', 'enable=false')
  when /el|centos/
    on host, puppet('resource', 'service', 'iptables', 'ensure=stopped', 'enable=false')
  when /ubuntu/
    on host, puppet('resource', 'service', 'ufw', 'ensure=stopped', 'enable=false')
  else
    logger.notify("Not sure how to clear firewall on #{host['platform']}")
  end
end

def setup_puppet(host)

  step 'Install puppet on agent'
  install_puppetlabs_release_repo host, 'pc1'
  configure_defaults_on host, 'foss'
  install_puppet_agent_on host
  configure_puppet_on(host, {})

  agenthostname = on(host, 'facter fqdn').stdout.strip

  pp = "file { '#{master.puppet['confdir']}/autosign.conf': ensure => file, content => '#{agenthostname}' }"
  apply_manifest_on(master, pp)

end

def teardown_puppet(host)
  step 'Purge puppet from agent'

  case host['platform']
  when /debian|ubuntu/
    on host, '/opt/puppetlabs/bin/puppet module install puppetlabs-apt', acceptable_exit_codes: [0, 1]
    clean_repo = "include apt\napt::source { 'pc1_repo': ensure => absent, notify => Package['puppet-agent'] }"
  when /fedora|el|centos/
    clean_repo = "yumrepo { 'pc1_repo': ensure => absent, notify => Package['puppet-agent'] }"
  else
    logger.notify("Not sure how to remove repos on #{host['platform']}")
    clean_repo = ''
  end

  pp = <<-EOS
#{clean_repo}
file { ['/etc/puppet', '/etc/puppetlabs']: ensure => absent, force => true, backup => false }
package { ['puppet-agent', 'puppet']: ensure => purged }
  EOS

  apply_manifest_on(host, pp)
end

def restart_puppetserver
  on master, puppet('resource', 'service', 'puppetserver', 'ensure=stopped')
  on master, puppet('resource', 'service', 'puppetserver', 'ensure=running')
end

def aem_license(module_root)
  license_file = File.join(module_root, 'spec', 'files', 'license.properties')
  return if File.exist?(license_file)
  File.foreach(license_file) do |line|
    match = line.match(/license.downloadID=(\S+)/)
    ENV['AEM_LICENSE'] = match.captures[0] if match
  end
end

module_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
aem_license(module_root)

unless ENV['BEAKER_provision'] == 'no'

  # Install module
  dsipatcher_mod = File.expand_path(File.join(module_root, 'spec', 'files', default.host_hash[:dispatcher_file]))
  scp_to(default, dsipatcher_mod, '/tmp/dispatcher-apache-module.so')

  aem_installer = File.expand_path(File.join(module_root, 'spec', 'files', 'aem-quickstart.jar'))
  scp_to(default, aem_installer, '/tmp/aem-quickstart.jar')
  on default, 'chmod 775 /tmp/aem-quickstart.jar'

  start_env = File.expand_path(File.join(module_root, 'spec', 'files', 'faux-start-env'))
  scp_to(default, start_env, '/tmp/faux-start-env')
  on default, 'chmod 775 /tmp/faux-start-env'

  ensure_script = File.expand_path(File.join(module_root, 'spec', 'files', 'ensure-running.sh'))
  scp_to(default, ensure_script, '/tmp/ensure-running.sh')
  on default, 'chmod 775 /tmp/ensure-running.sh'
  # Credit to Puppetlabs Puppet Agent project,
  # This was the only place i could find that had an example that
  # made all of this stuff work.

  # Install puppet-server on master
  step 'Setup Puppet'
  install_puppetlabs_release_repo master, 'pc1'

  options['is_puppetserver'] = true
  master['puppetservice'] = 'puppetserver'
  master['puppetserver-confdir'] = '/etc/puppetlabs/puppetserver/conf.d'
  master['type'] = 'aio'
  install_puppet_agent_on master
  install_package master, 'puppetserver'
  master['use-service'] = true

  on master, puppet('module', 'install', 'puppetlabs-stdlib'), acceptable_exit_codes: [0, 1]
  on master, puppet('module', 'install', 'puppetlabs-concat'), acceptable_exit_codes: [0, 1]
  on master, puppet('module', 'install', 'puppetlabs-apache'), acceptable_exit_codes: [0, 1]
  on master, puppet('module', 'install', 'puppetlabs-java'), acceptable_exit_codes: [0, 1]

  setup_puppet default
  stop_firewall_on(master)
  stop_firewall_on(default)
  clear_ssl
  on(default, 'puppet agent --enable')

end

# Install module
configure_defaults_on master, 'aio'
install_dev_puppet_module_on(master, source: module_root, module_name: 'aem')

RSpec.shared_examples 'setup aem' do

  license = ENV['AEM_LICENSE'] || 'fake-key-for-testing'

  site = <<-MANIFEST
    'node \"agent\" {
      File { backup => false, owner => \"aem\", group => \"aem\" }

      group { \"aem\" : ensure => \"present\" }

      user { \"aem\" : ensure => \"present\", gid =>  \"aem\" }

      file { \"/opt/faux\" :
        ensure          => \"directory\",
      }

      file { \"/opt/faux/crx-quickstart\" :
        ensure          => \"directory\",
      }
      file { \"/opt/faux/crx-quickstart/bin\" :
        ensure        => \"directory\",
      }
      file { \"/opt/faux/crx-quickstart/bin/start-env\" :
        ensure        => \"file\",
        source        => "/tmp/faux-start-env",
        mode          => \"0755\",
      }

      file { \"/opt/faux/crx-quickstart/bin/start.orig\" :
        ensure        => \"file\",
        content       => \"\",
        mode          => \"0755\",
      }

      file { \"/opt/faux/crx-quickstart/repository\" :
        ensure        => \"directory\",
      }

      file { \"/opt/faux/crx-quickstart/app\" :
        ensure          => \"directory\",
      }

      file { \"/opt/faux/crx-quickstart/app/cq-quickstart-6.1.0-standalone.jar\" :
        ensure        => \"file\",
        content       => \"\",
      }

      class { \"java\" : }

      file { \"/opt/aem\" : ensure => directory }

      \$osgi = [{
        \"SegmentNodeStore-Author\" => {
          \"pid\"        => \"org.apache.jackrabbit.oak.plugins.segment.SegmentNodeStoreService\",
          \"properties\" => {
            \"tarmk.size\" => 512,
            \"pauseCompaction\" => true,
          }
        },
        \"org.apache.sling.security.impl.ReferrerFilter\" => {
          \"allow.empty\"    => true,
          \"allow.hosts\"    => [\"author.localhost.localmachine\"],
          #\"filter.methods\" => [\"POST\", \"PUT\", \"DELETE\", \"TRACE\"],
        }
      }]

      aem::instance { \"author\" :
        debug_port      => 30303,
        group           => \"vagrant\",
        home            => \"/opt/aem/author\",
        jvm_mem_opts    => \"-Xmx2048m\",
        osgi_configs    => \$osgi,
        source          => \"/tmp/aem-quickstart.jar\",
        timeout         => 1200,
        user            => \"vagrant\",
      }

      Class[\"java\"] -> File[\"/opt/aem\"] -> Aem::Instance <| |>

      Aem::License {
        customer    => \"Vagrant Test\",
        license_key => \"#{license}\",
        version     => \"6.1.0\",
      }

      aem::license { \"author\" :
        group   => \"vagrant\",
        user    => \"vagrant\",
        home    => \"/opt/aem/author\",
      }

      Aem::License[\"author\"] ~> Aem::Service[\"author\"]
    }'
  MANIFEST

  pp = <<-MANIFEST
    file {
      '#{master.puppet['codedir']}/environments/production/manifests/site.pp':
        ensure => file,
        content => #{site}
    }
  MANIFEST

  apply_manifest_on(master, pp, catch_failures: true)

  restart_puppetserver
  fqdn = on(master, 'facter fqdn').stdout.strip
  fqdn = fqdn.chop if fqdn.end_with?('.')

  on(
    default,
    puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
    acceptable_exit_codes: [0, 2]
  )

  on(default, '/tmp/ensure-running.sh')

end

RSpec.shared_examples 'update aem' do

  site = <<-MANIFEST
    'node \"agent\" {
      File { backup => false, owner => \"aem\", group => \"aem\" }

      aem::service { \"author\" :
        home            => \"/opt/aem/author\",
        user            => \"vagrant\",
        group           => \"vagrant\",
        status          => \"disabled\",
      }
    }'
  MANIFEST

  pp = <<-MANIFEST
    file {
      '#{master.puppet['codedir']}/environments/production/manifests/site.pp':
        ensure => file,
        content => #{site}
    }
  MANIFEST

  apply_manifest_on(master, pp, catch_failures: true)
  restart_puppetserver
  fqdn = on(master, 'facter fqdn').stdout.strip
  on(
    default,
    puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
    acceptable_exit_codes: [0, 2]
  )

  site = <<-MANIFEST
    'node \"agent\" {
      File { backup => false, owner => \"aem\", group => \"aem\" }

      aem::instance { \"author\" :
        source          => \"/tmp/aem-quickstart.jar\",
        home            => \"/opt/aem/author\",
        user            => \"vagrant\",
        group           => \"vagrant\",
        jvm_mem_opts    => \"-Xmx2048m -XX:MaxPermSize=512M\",
        jvm_opts        => \"-XX:+UseParNewGC\",
        sample_content  => false,
        status          => \"running\",
        type            => \"publish\",
        timeout         => 1200,
        port            => 4503,
        debug_port      => 54321,
        context_root    => \"aem-publish\",
        runmodes    => [\"dev\", \"client\", \"server\", \"mock\"],
      }
    }'
  MANIFEST

  pp = <<-MANIFEST
    file {
      '#{master.puppet['codedir']}/environments/production/manifests/site.pp':
        ensure => file,
        content => #{site}
    }
  MANIFEST

  apply_manifest_on(master, pp, catch_failures: true)
  restart_puppetserver
  fqdn = on(master, 'facter fqdn').stdout.strip
  on(
    default,
    puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
    acceptable_exit_codes: [0, 2]
  )
  on(
    default,
    puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
    acceptable_exit_codes: [0]
  )
end

RSpec.configure do |c|

  c.filter_run_excluding(license: false) unless ENV['AEM_LICENSE']
  c.formatter = :documentation
end
