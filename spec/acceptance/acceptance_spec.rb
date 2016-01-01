require 'spec_helper_acceptance'

describe 'aem::instance' do

  describe 'aem::instance first run' do

    let :facts do
      {
        :environment => :root
      }
    end

    let :license do
      ENV['AEM_LICENSE'] || 'fake-key-for-testing'
    end

    context 'create' do

      it 'should work with no errors' do

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

            \$osgi = {
              \"org.apache.jackrabbit.oak.plugins.segment.SegmentNodeStoreService\" => {
                \"tarmk.size" => 512,
                \"pauseCompaction\" => true,
              }
            }

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

        apply_manifest_on(master, pp, :catch_failures => true)

        restart_puppetserver
        fqdn = on(master, 'facter fqdn').stdout.strip
        fqdn = fqdn.chop if fqdn.end_with?(".")

        on(
          default,
          puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
          :acceptable_exit_codes => [0, 2]
        )

        on(
          default,
          puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
          :acceptable_exit_codes => [0]
        )
      end

      it 'should have unpacked the standalone jar' do
        shell('find /opt/aem/author/crx-quickstart -name "cq-quickstart-*-standalone*.jar" -type f') do |result|
          expect(result.stdout).to match(%r{^(\S+)/crx-quickstart/app/cq-quickstart-([0-9.]+)-standalone.*\.jar})
        end
      end

      it 'should be owned by specified user/group' do
        shell('stat -c "%U:%G" /opt/aem/author/crx-quickstart/app/cq-quickstart*.jar') do |result|
          expect(result.stdout).to match('vagrant:vagrant')
        end
      end

    end

    context 'start-env config' do
      it 'should update the type' do
        shell("grep TYPE=\\'author\\' /opt/aem/author/crx-quickstart/bin/start-env", :acceptable_exit_codes => 0)
      end

      it 'should update the port' do
        shell('grep PORT=4502 /opt/aem/author/crx-quickstart/bin/start-env', :acceptable_exit_codes => 0)
      end

      it 'should update the sample content' do
        shell("grep SAMPLE_CONTENT=\\'\\' /opt/aem/author/crx-quickstart/bin/start-env",
              :acceptable_exit_codes => 0)
      end

      it 'should update the context root' do
        shell('grep CONTEXT_ROOT /opt/aem/author/crx-quickstart/bin/start-env', :acceptable_exit_codes => 1)
      end

    end

    context 'license' do
      context 'author' do
        it 'should have license file' do
          shell('test -f /opt/aem/author/license.properties', :acceptable_exit_codes => 0)
        end

        it 'should have correct owner:group' do
          shell('stat -c "%U:%G" /opt/aem/author/license.properties') do |result|
            expect(result.stdout).to match('vagrant:vagrant')
          end
        end

        it 'should contain customer' do
          shell('grep "license.customer.name=Vagrant Test" /opt/aem/author/license.properties',
                :acceptable_exit_codes => 0)
        end

        it 'should contain licnese_key' do
          shell("grep -- \"license.downloadID=#{license}\" /opt/aem/author/license.properties",
                :acceptable_exit_codes => 0)
        end

        it 'should contain version' do
          shell('grep "license.product.version=6.1.0" /opt/aem/author/license.properties',
                :acceptable_exit_codes => 0)
        end
      end

    end

    context 'file osgi configs' do
      it 'should contain osgi config file' do
        shell('test -f /opt/aem/author/crx-quickstart/install/org.apache.jackrabbit.oak.plugins.segment.SegmentNodeStoreService.config', :acceptable_exit_codes => 0)
      end

      it 'should contain the tarmk file config' do
        shell('grep "tarmk.size=L\"512\"" /opt/aem/author/crx-quickstart/install/org.apache.jackrabbit.oak.plugins.segment.SegmentNodeStoreService.config',
              :acceptable_exit_codes => 0)
      end

      it 'should contain the pauseCompatction config' do
        shell('grep "pauseCompaction=B\"true\"" /opt/aem/author/crx-quickstart/install/org.apache.jackrabbit.oak.plugins.segment.SegmentNodeStoreService.config',
              :acceptable_exit_codes => 0)
      end
    end

    context 'services running' do

      describe service('aem-author') do
        it { should be_running }
        it { should be_enabled }
      end
    end

    context 'running instances' do
      it 'should start author with correct port and context root' do

        valid = false
        catch(:started) do
          Timeout.timeout(200) do
            Kernel.loop do
              begin
                shell('curl -I http://localhost:4502/') do |result|
                  if result.stdout =~ %r{HTTP\/1.1 (302|401|200)}
                    valid = true
                    throw :started if valid
                    break
                  end
                end
              rescue
              end
              sleep 15
            end
          end
        end
        expect(valid).to eq(true)
      end
    end

    context 'console osgi configs', license: false do

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

            aem::osgi::config { \"org.apache.sling.installer.provider.jcr.impl.JcrInstaller\":
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

        apply_manifest_on(master, pp, :catch_failures => true)
        restart_puppetserver
        fqdn = on(master, 'facter fqdn').stdout.strip
        fqdn = fqdn.chop if fqdn.end_with?(".")

        on(
          default,
          puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
          :acceptable_exit_codes => [0, 2]
        )

        on(
          default,
          puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
          :acceptable_exit_codes => [0]
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

        apply_manifest_on(master, pp, :catch_failures => true)
        restart_puppetserver
        fqdn = on(master, 'facter fqdn').stdout.strip
        fqdn = fqdn.chop if fqdn.end_with?(".")

        on(
          default,
          puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
          :acceptable_exit_codes => [0, 2]
        )

        site = <<-MANIFEST
          'node \"agent\" {

            \$osgi = {
              \"allow.hosts\"    => [\"author.localhost\"],
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

        apply_manifest_on(master, pp, :catch_failures => true)
        restart_puppetserver
        fqdn = on(master, 'facter fqdn').stdout.strip
        fqdn = fqdn.chop if fqdn.end_with?(".")

        on(
          default,
          puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
          :acceptable_exit_codes => [0, 2]
        )

        on(
          default,
          puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
          :acceptable_exit_codes => [0]
        )

        shell('curl http://localhost:4502/system/console/configMgr/org.apache.sling.security.impl.ReferrerFilter.json -u admin:admin') do |result|
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

        apply_manifest_on(master, pp, :catch_failures => true)
        restart_puppetserver
        fqdn = on(master, 'facter fqdn').stdout.strip
        fqdn = fqdn.chop if fqdn.end_with?(".")

        on(
          default,
          puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
          :acceptable_exit_codes => [0, 2]
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

        apply_manifest_on(master, pp, :catch_failures => true)
        restart_puppetserver
        fqdn = on(master, 'facter fqdn').stdout.strip
        fqdn = fqdn.chop if fqdn.end_with?(".")

        on(
          default,
          puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
          :acceptable_exit_codes => [0, 2]
        )

        on(
          default,
          puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
          :acceptable_exit_codes => [0]
        )

        shell('curl http://localhost:4502/system/console/configMgr/org.apache.sling.security.impl.ReferrerFilter.json -u admin:admin') do |result|
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
    end
  end

  describe 'aem::instance updated' do

    let :facts do
      {
        :environment => :root
      }
    end

    context 'update service' do
      it 'needs to have services redefined to update state' do
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

        apply_manifest_on(master, pp, :catch_failures => true)
        restart_puppetserver
        fqdn = on(master, 'facter fqdn').stdout.strip
        on(
          default,
          puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
          :acceptable_exit_codes => [0, 2]
        )
      end
    end

    context 'update resource' do
      it 'should work with no errors' do
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

        apply_manifest_on(master, pp, :catch_failures => true)
        restart_puppetserver
        fqdn = on(master, 'facter fqdn').stdout.strip
        on(
          default,
          puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
          :acceptable_exit_codes => [0, 2]
        )
        on(
          default,
          puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
          :acceptable_exit_codes => [0]
        )
      end
    end

    context 'start-env config updates' do
      it 'should update the type' do
        shell("grep TYPE=\\'publish\\' /opt/aem/author/crx-quickstart/bin/start-env", :acceptable_exit_codes => 0)
      end

      it 'should update the port' do
        shell('grep PORT=4503 /opt/aem/author/crx-quickstart/bin/start-env', :acceptable_exit_codes => 0)
      end

      it 'should update the runmodes' do
        shell("grep RUNMODES=\\'dev,client,server,mock\\' /opt/aem/author/crx-quickstart/bin/start-env",
              :acceptable_exit_codes => 0)
      end

      it 'should update the sample content' do
        shell("grep SAMPLE_CONTENT=\\'nosamplecontent\\' /opt/aem/author/crx-quickstart/bin/start-env",
              :acceptable_exit_codes => 0)
      end

      it 'should update the debug port' do
        shell("grep -- 'DEBUG_PORT=54321' /opt/aem/author/crx-quickstart/bin/start-env", :acceptable_exit_codes => 0)
      end

      it 'should update the context root' do
        shell("grep CONTEXT_ROOT=\\'aem-publish\\' /opt/aem/author/crx-quickstart/bin/start-env",
              :acceptable_exit_codes => 0)
      end

      it 'should update the jvm memory settings' do
        shell("grep -- \"JVM_MEM_OPTS='-Xmx2048m -XX:MaxPermSize=512M'\" /opt/aem/author/crx-quickstart/bin/start-env",
              :acceptable_exit_codes => 0)
      end

      it 'should update the jvm settings' do
        shell("grep -- JVM_OPTS=\\'-XX:+UseParNewGC\\' /opt/aem/author/crx-quickstart/bin/start-env",
              :acceptable_exit_codes => 0)
      end
    end

    context 'services running in new state' do

      describe service('aem-author') do
        it { should_not be_enabled }
        it { should be_running }
      end

    end

    context 'running instances' do
      it 'should have restarted correct port and context root' do

        valid = false
        catch(:started) do
          Timeout.timeout(200) do
            Kernel.loop do

              begin
                shell('curl -I http://localhost:4502/aem-publish/') do |result|
                  if result.stdout =~ %r{HTTP\/1.1 (302|401|200)}
                    valid = true
                    throw :started if valid
                    break
                  end
                end
              rescue
              end
              sleep 15
            end
          end
        end
        expect(valid).to eq(true)
      end
    end

  end

  describe 'destroy' do

    it 'should work with no errors' do

      site = <<-MANIFEST
      'node \"agent\" {
        File { backup => false, owner => \"aem\", group => \"aem\" }

        aem::instance { \"author\" :
          ensure       => absent,
          manage_user  => false,
          manage_group => false,
          manage_home  => false,
          user         => \"vagrant\",
          group        => \"vagrant\",
          home         => \"/opt/aem/author\",
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

      on default, puppet('resource', 'service', 'aem-author', 'ensure=stopped')
      apply_manifest_on(master, pp, :catch_failures => true)
      fqdn = on(master, 'facter fqdn').stdout.strip
      restart_puppetserver
      on(
        default,
        puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
        :acceptable_exit_codes => [0, 2]
      )
    end

    it 'should have removed instance repository' do
      shell('ls /opt/aem/author/crx-quickstart', :acceptable_exit_codes => 2)
    end

  end
end
