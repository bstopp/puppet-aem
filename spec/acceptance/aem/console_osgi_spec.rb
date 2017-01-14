require 'spec_helper_acceptance'

describe 'console osgi configs', license: false do

  let(:facts) do
    {
      environment: :root
    }
  end

  include_examples 'setup aem'

  it 'should work with no errors' do

    site = <<-MANIFEST
      'node \"agent\" {

        \$osgi = {
          \"handler.schemes\"                     => [ \"jcrinstall\", \"launchpad\" ],
          \"sling.jcrinstall.folder.name.regexp\" => \".*/(install|config|bundles)$\",
          \"sling.jcrinstall.folder.max.depth\"   => 5,
          \"sling.jcrinstall.search.path\"        => [ \"/libs:100\", \"/apps:200\", \"/doesnotexist:10\" ],
          \"sling.jcrinstall.new.config.path\"    => \"system/config\",
          \"sling.jcrinstall.signal.path\"        => \"/system/sling/installer/jcr/pauseInstallation\",
          \"sling.jcrinstall.enable.writeback\"   => false
        }

        aem::osgi::config { \"JCRInstaller\" :
          ensure         => present,
          pid            => \"org.apache.sling.installer.provider.jcr.impl.JcrInstaller\",
          properties     => \$osgi,
          handle_missing => \"remove\",
          home           => \"/opt/aem/author\",
          password       => \"admin\",
          type           => \"console\",
          username       => \"admin\",
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
    fqdn = fqdn.chop if fqdn.end_with?('.')

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

  it 'should work handle remove existing configuration' do

    site = <<-MANIFEST
      'node \"agent\" {

        \$osgi = {
          \"allow.empty\"    => true,
          \"allow.hosts\"    => [\"author.localhost.localmachine\"],
          \"filter.methods\" => [\"POST\", \"PUT\", \"DELETE\", \"TRACE\"],
        }
        aem::osgi::config { \"org.apache.sling.security.impl.ReferrerFilter\" :
          ensure         => present,
          properties     => \$osgi,
          handle_missing => \"remove\",
          home           => \"/opt/aem/author\",
          password       => \"admin\",
          type           => \"console\",
          username       => \"admin\",
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
    fqdn = fqdn.chop if fqdn.end_with?('.')

    on(
      default,
      puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
      acceptable_exit_codes: [0, 2]
    )

    site = <<-MANIFEST
      'node \"agent\" {

        \$osgi = {
          \"allow.hosts\"    => [\"author.localhost\"],
        }
        aem::osgi::config { \"ReferrerFilter\" :
          ensure         => present,
          pid            => \"org.apache.sling.security.impl.ReferrerFilter\",
          properties     => \$osgi,
          handle_missing => \"remove\",
          home           => \"/opt/aem/author\",
          password       => \"admin\",
          type           => \"console\",
          username       => \"admin\",
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
    fqdn = fqdn.chop if fqdn.end_with?('.')

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

    cmd = 'curl http://localhost:4502/system/console/configMgr/org.apache.sling.security.impl.ReferrerFilter.json '
    cmd += '-u admin:admin'
    shell(cmd) do |result|
      jsonresult = JSON.parse(result.stdout)
      configed_props = jsonresult[0]['properties']
      expect(configed_props['allow.empty']['is_set']).to eq(false)

      expect(configed_props['allow.hosts.regexp']['is_set']).to eq(false)

      expect(configed_props['allow.hosts']['is_set']).to eq(true)
      expect(configed_props['allow.hosts']['values']).to eq(['author.localhost'])

      expect(configed_props['filter.methods']['is_set']).to eq(false)
    end
  end

  it 'should work handle merge existing configuration' do

    site = <<-MANIFEST
      'node \"agent\" {

        \$osgi = {
          \"allow.empty\"    => true,
          \"allow.hosts\"    => [\"author.localhost.localmachine\"],
          \"filter.methods\" => [\"POST\", \"PUT\", \"DELETE\", \"TRACE\"],
        }
        aem::osgi::config { \"org.apache.sling.security.impl.ReferrerFilter\" :
          ensure         => present,
          properties     => \$osgi,
          handle_missing => \"remove\",
          home           => \"/opt/aem/author\",
          password       => \"admin\",
          type           => \"console\",
          username       => \"admin\",
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
    fqdn = fqdn.chop if fqdn.end_with?('.')

    on(
      default,
      puppet("agent #{DEBUG} --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
      acceptable_exit_codes: [0, 2]
    )

    site = <<-MANIFEST
      'node \"agent\" {

        \$osgi = {
          \"allow.hosts\"    => [\"author.localhost\"],
        }
        aem::osgi::config { \"org.apache.sling.security.impl.ReferrerFilter\" :
          ensure         => present,
          properties     => \$osgi,
          handle_missing => \"merge\",
          home           => \"/opt/aem/author\",
          password       => \"admin\",
          type           => \"console\",
          username       => \"admin\",
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
    fqdn = fqdn.chop if fqdn.end_with?('.')

    on(
      default,
      puppet("agent #{DEBUG} --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
      acceptable_exit_codes: [0, 2]
    )

    on(
      default,
      puppet("agent #{DEBUG} --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
      acceptable_exit_codes: [0]
    )

    cmd = 'curl http://localhost:4502/system/console/configMgr/org.apache.sling.security.impl.ReferrerFilter.json '
    cmd += '-u admin:admin'
    shell(cmd) do |result|
      jsonresult = JSON.parse(result.stdout)
      configed_props = jsonresult[0]['properties']
      expect(configed_props['allow.empty']['is_set']).to eq(true)
      expect(configed_props['allow.empty']['value']).to eq(true)

      expect(configed_props['allow.hosts.regexp']['is_set']).to eq(false)

      expect(configed_props['allow.hosts']['is_set']).to eq(true)
      expect(configed_props['allow.hosts']['values']).to eq(['author.localhost'])

      expect(configed_props['filter.methods']['is_set']).to eq(true)
      expect(configed_props['filter.methods']['values']).to eq(['POST', 'PUT', 'DELETE', 'TRACE'])

    end
  end

  it 'should remove configurations' do

    site = <<-MANIFEST
      'node \"agent\" {

        \$osgi = {
          \"allow.empty\"    => true,
          \"allow.hosts\"    => [\"author.localhost.localmachine\"],
          \"filter.methods\" => [\"POST\", \"PUT\", \"DELETE\", \"TRACE\"],
        }
        aem::osgi::config { \"org.apache.sling.security.impl.ReferrerFilter\" :
          ensure         => present,
          properties     => \$osgi,
          handle_missing => \"remove\",
          home           => \"/opt/aem/author\",
          password       => \"admin\",
          type           => \"console\",
          username       => \"admin\",
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
    fqdn = fqdn.chop if fqdn.end_with?('.')

    on(
      default,
      puppet("agent #{DEBUG} --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
      acceptable_exit_codes: [0, 2]
    )

    site = <<-MANIFEST
      'node \"agent\" {

        aem::osgi::config { \"org.apache.sling.security.impl.ReferrerFilter\" :
          ensure         => absent,
          home           => \"/opt/aem/author\",
          password       => \"admin\",
          type           => \"console\",
          username       => \"admin\",
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
    fqdn = fqdn.chop if fqdn.end_with?('.')

    on(
      default,
      puppet("agent #{DEBUG} --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
      acceptable_exit_codes: [0, 2]
    )

    on(
      default,
      puppet("agent #{DEBUG} --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
      acceptable_exit_codes: [0]
    )

    cmd = 'curl -s -o /dev/null -w "%{http_code}" '
    cmd += 'http://localhost:4502/system/console/configMgr/org.apache.sling.security.impl.ReferrerFilter.json '
    cmd += '-u admin:admin'
    shell(cmd) do |result|
      expect(result.stdout).to eq(/404/)
    end
  end
end
