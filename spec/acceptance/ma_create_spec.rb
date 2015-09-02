require 'spec_helper_acceptance'

def parser_opts 
  {
    :main => {
    :stringify_facts => false,
    :parser => 'future',
    :color => 'ansi',
    :certificate_revocation => false,
    :ssldir => '$vardir/ssl',
    :server => master,
    },
    :agent => {:stringify_facts => false, :cfacter => true, },
    :master => {:stringify_facts => false, :cfacter => true},
  }
end

# A lot of this is from Puppet Agent module,
# since it is the only one i can find that has a Master/Agent test case.
def setup_puppet(host)

  step 'Install puppet on agent'
  configure_defaults_on host, 'foss'
  install_puppet_on host
  configure_puppet_on(host, {})

  agenthostname = on(host, 'facter hostname').stdout.strip
  pp = "file { '#{master.puppet['confdir']}/autosign.conf': ensure => file, content => #{agenthostname} }"
  apply_manifest_on(master, pp)

  step "Clear SSL on all hosts"
  hosts.each do |host|
    stop_firewall_on host
    ssldir = on(host, puppet('agent --configprint ssldir')).stdout.chomp
    on(host, "rm -rf #{ssldir}/*")
  end

end

def teardown_puppet(host)
  step "Purge puppet from agent"

  case host['platform']
  when /debian|ubuntu/
    on host, '/opt/puppetlabs/bin/puppet module install puppetlabs-apt', { :acceptable_exit_codes => [0,1] }
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

if only_host_with_role(hosts, 'agent')

  describe 'aem::instance class' do

    site = <<-MANIFEST
'node \"centos-70-x64-agent\" {

  File { backup => false }

  class { \"java\" : }

  aem::instance { \"aem\" :
    source          => \"/tmp/aem-quickstart.jar\",
    user            => \"vagrant\",
    group           => \"vagrant\",
    jvm_mem_opts    => \"-Xmx2048m\",
    sample_content  => false,
  }

  Class[\"java\"] -> Aem::Instance <| |>
  
}'
MANIFEST

    context 'install on agent' do
      before(:all) do
        setup_puppet default
        pp = "file { '#{master.puppet['codedir']}/environments/production/manifests/site.pp': ensure => file, content => #{site} }"
        apply_manifest_on(master, pp, :catch_failures => true)

      end

      after(:all) do
        teardown_puppet default
        pp = "file { '#{master.puppet['confdir']}/manifests/site.pp': ensure => absent }"
        apply_manifest_on(master, pp, :catch_failures => true)
      end

      it 'should work with no errors' do
        with_puppet_running_on(master, server_opts, master.tmpdir('puppet')) do
          fqdn = on(master, 'facter fqdn').stdout.strip
          on default, puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"), { :acceptable_exit_codes => [0,2] }
          on default, puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"), { :acceptable_exit_codes => [0] }
        end
      end

    end
  end

end