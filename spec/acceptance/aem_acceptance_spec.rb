require 'spec_helper_acceptance'

describe 'aem::instance acceptance' do

  describe 'aem::instance first run' do

    let(:facts) do
      {
        :environment => :root
      }
    end

    let(:license) do
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

        apply_manifest_on(master, pp, :catch_failures => true)

        restart_puppetserver
        fqdn = on(master, 'facter fqdn').stdout.strip
        fqdn = fqdn.chop if fqdn.end_with?('.')

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
          expect(result.stdout).to match(%r|^(\S+)/crx-quickstart/app/cq-quickstart-([0-9.]+)-standalone.*\.jar|)
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
      it 'should contain osgi config file SegmentNodeStoreService' do
        cmd = 'test -f /opt/aem/author/crx-quickstart/install/'
        cmd += 'org.apache.jackrabbit.oak.plugins.segment.SegmentNodeStoreService.config'
        shell(cmd, :acceptable_exit_codes => 0)
      end

      it 'should contain the tarmk file config' do
        cmd = 'grep "tarmk.size=L\"512\"" '
        cmd += '/opt/aem/author/crx-quickstart/install/'
        cmd += 'org.apache.jackrabbit.oak.plugins.segment.SegmentNodeStoreService.config'
        shell(cmd, :acceptable_exit_codes => 0)
      end

      it 'should contain the pauseCompatction config' do
        cmd = 'grep "pauseCompaction=B\"true\"" '
        cmd += '/opt/aem/author/crx-quickstart/install/'
        cmd += 'org.apache.jackrabbit.oak.plugins.segment.SegmentNodeStoreService.config'
        shell(cmd, :acceptable_exit_codes => 0)
      end

      it 'should contain osgi config file ReferrerFilter' do
        cmd = 'test -f /opt/aem/author/crx-quickstart/install/org.apache.sling.security.impl.ReferrerFilter.config'
        shell(cmd, :acceptable_exit_codes => 0)
      end

      it 'should contain the empty allow config' do
        cmd = 'grep "allow.empty=B\"true\"" '
        cmd += '/opt/aem/author/crx-quickstart/install/org.apache.sling.security.impl.ReferrerFilter.config'
        shell(cmd, :acceptable_exit_codes => 0)
      end

      it 'should contain the allow hosts config' do
        cmd = 'grep "allow.hosts=\[\"author.localhost.localmachine\"\]" '
        cmd += '/opt/aem/author/crx-quickstart/install/org.apache.sling.security.impl.ReferrerFilter.config'
        shell(cmd, :acceptable_exit_codes => 0)
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
                valid = false
              end
              sleep 15
            end
          end
        end
        expect(valid).to eq(true)
      end
    end

    context 'console osgi configs', :license => false do

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

        apply_manifest_on(master, pp, :catch_failures => true)
        restart_puppetserver
        fqdn = on(master, 'facter fqdn').stdout.strip
        fqdn = fqdn.chop if fqdn.end_with?('.')

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
        fqdn = fqdn.chop if fqdn.end_with?('.')

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

        apply_manifest_on(master, pp, :catch_failures => true)
        restart_puppetserver
        fqdn = on(master, 'facter fqdn').stdout.strip
        fqdn = fqdn.chop if fqdn.end_with?('.')

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

        apply_manifest_on(master, pp, :catch_failures => true)
        restart_puppetserver
        fqdn = on(master, 'facter fqdn').stdout.strip
        fqdn = fqdn.chop if fqdn.end_with?('.')

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
        fqdn = fqdn.chop if fqdn.end_with?('.')

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
    end

    context 'sling resource spec', :license => false do
      context 'create' do
        it 'should work with no errors' do

          site = <<-MANIFEST
            'node \"agent\" {

              \$props = {
                \"jcr:primaryType\" => \"nt:unstructured\",
                \"title\" => \"title string\",
                \"text\"  => \"text string\",
                \"child\" => {
                  \"jcr:primaryType\" => \"nt:unstructured\",
                  \"property\" => \"value\",
                  \"grandchild\" => {
                    \"jcr:primaryType\" => \"nt:unstructured\",
                    \"child attrib\" => \"another value\",
                    \"array\" => [\"this\", \"is\", \"an\", \"array\"]
                  }
                }
              }

              aem_sling_resource { \"test node\" :
                ensure         => present,
                path           => \"/content/testnode\",
                properties     => \$props,
                handle_missing => \"remove\",
                home           => \"/opt/aem/author\",
                password       => \"admin\",
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
          fqdn = fqdn.chop if fqdn.end_with?('.')

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
          cmd = 'curl http://localhost:4502/content/testnode.infinity.json '
          cmd += '-u admin:admin'
          shell(cmd) do |result|
            jsonresult = JSON.parse(result.stdout)

            expect(jsonresult['title']).to eq('title string')
            expect(jsonresult['text']).to eq('text string')
            expect(jsonresult['child']['property']).to eq('value')
            expect(jsonresult['child']['grandchild']['child attrib']).to eq('another value')
            expect(jsonresult['child']['grandchild']['array']).to eq(['this', 'is', 'an', 'array'])
          end
        end
      end

      context 'should update with no errors' do
        it 'handle_missing == ignore' do
          site = <<-MANIFEST
            'node \"agent\" {

              \$props = {
                \"jcr:primaryType\" => \"nt:unstructured\",
                \"jcr:title\" => \"title string\",
                \"newtext\"  => \"text string\",
                \"child\" => {
                  \"anotherproperty\" => \"value\",
                  \"grandchild2\" => {
                    \"jcr:primaryType\" => \"nt:unstructured\",
                    \"child attrib\" => \"another value\",
                    \"array\" => [\"this\", \"is\", \"an\", \"array\"]
                  }
                },
                \"child2\" => {
                  \"jcr:primaryType\" => \"nt:unstructured\",
                  \"property\" => \"value\",
                  \"grandchild\" => {
                    \"jcr:primaryType\" => \"nt:unstructured\",
                    \"child attrib\" => \"another value\",
                    \"array\" => [\"this\", \"is\", \"an\", \"array\"]
                  }
                }
              }

              aem_sling_resource { \"test node\" :
                ensure         => present,
                path           => \"/content/testnode\",
                properties     => \$props,
                handle_missing => \"ignore\",
                home           => \"/opt/aem/author\",
                password       => \"admin\",
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
          fqdn = fqdn.chop if fqdn.end_with?('.')

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
          cmd = 'curl http://localhost:4502/content/testnode.infinity.json '
          cmd += '-u admin:admin'
          shell(cmd) do |result|
            jsonresult = JSON.parse(result.stdout)

            expect(jsonresult['title']).to eq('title string')
            expect(jsonresult['text']).to eq('text string')
            expect(jsonresult['child']['property']).to eq('value')
            expect(jsonresult['child']['grandchild']['child attrib']).to eq('another value')
            expect(jsonresult['child']['grandchild']['array']).to eq(['this', 'is', 'an', 'array'])

            expect(jsonresult['child']['anotherproperty']).to eq('value')
            expect(jsonresult['child']['grandchild2']['child attrib']).to eq('another value')
            expect(jsonresult['child']['grandchild2']['array']).to eq(['this', 'is', 'an', 'array'])

            expect(jsonresult['jcr:title']).to eq('title string')
            expect(jsonresult['newtext']).to eq('text string')
            expect(jsonresult['child2']['property']).to eq('value')
            expect(jsonresult['child2']['grandchild']['child attrib']).to eq('another value')
            expect(jsonresult['child2']['grandchild']['array']).to eq(['this', 'is', 'an', 'array'])
          end
        end

        it 'handle_missing == remove' do
          site = <<-MANIFEST
            'node \"agent\" {

              \$props = {
                \"jcr:primaryType\" => \"nt:unstructured\",
                \"jcr:title\" => \"title string\",
                \"newtext\"  => \"text string\",
                \"child\" => {
                  \"anotherproperty\" => \"new value\",
                  \"grandchild2\" => {
                    \"jcr:primaryType\" => \"nt:unstructured\",
                    \"child attrib\" => \"changed value\",
                    \"array\" => [\"this\", \"is\", \"a\", \"longer\", \"array\"]
                  }
                },
                \"child2\" => {
                  \"jcr:primaryType\" => \"nt:unstructured\",
                  \"property\" => \"value\",
                  \"grandchild\" => {
                    \"jcr:primaryType\" => \"nt:unstructured\",
                    \"child attrib\" => \"another value\"
                  }
                }
              }

              aem_sling_resource { \"test node\" :
                ensure         => present,
                path           => \"/content/testnode\",
                properties     => \$props,
                handle_missing => \"remove\",
                home           => \"/opt/aem/author\",
                password       => \"admin\",
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
          fqdn = fqdn.chop if fqdn.end_with?('.')

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
          cmd = 'curl http://localhost:4502/content/testnode.infinity.json '
          cmd += '-u admin:admin'
          shell(cmd) do |result|
            jsonresult = JSON.parse(result.stdout)

            expect(jsonresult['title']).to be_nil
            expect(jsonresult['text']).to be_nil
            expect(jsonresult['child']['property']).to be_nil
            expect(jsonresult['child']['grandchild']).to be_nil

            expect(jsonresult['child']['anotherproperty']).to eq('new value')
            expect(jsonresult['child']['grandchild2']['child attrib']).to eq('changed value')
            expect(jsonresult['child']['grandchild2']['array']).to eq(['this', 'is', 'a', 'longer', 'array'])

            expect(jsonresult['jcr:title']).to eq('title string')
            expect(jsonresult['newtext']).to eq('text string')
            expect(jsonresult['child2']['property']).to eq('value')
            expect(jsonresult['child2']['grandchild']['child attrib']).to eq('another value')
            expect(jsonresult['child2']['grandchild']['array']).to be_nil
          end
        end
      end

      context 'destroy' do

        it 'should work with no errors' do
          site = <<-MANIFEST
            'node \"agent\" {

              aem_sling_resource { \"test node\" :
                ensure         => absent,
                path           => \"/content/testnode\",
                home           => \"/opt/aem/author\",
                password       => \"admin\",
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
          fqdn = fqdn.chop if fqdn.end_with?('.')

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
          cmd = 'curl http://localhost:4502/content/testnode.infinity.json '
          cmd += '-u admin:admin'
          shell(cmd) do |result|
            expect(result.stdout).to match(/404/)
          end
        end
      end
    end
  end

  describe 'replication agent', :license => false do
    context 'create agent' do

      let(:desc) do
        '**Managed by Puppet. Any changes made will be overwritten** Custom Description'
      end

      it 'should create with all properties' do
        site = <<-MANIFEST
          'node \"agent\" {
            File { backup => false, owner => \"aem\", group => \"aem\" }

            aem::agent::replication { \"agent1\" :
              agent_user            => \"agentuser\",
              batch_enabled         => true,
              batch_max_wait        => 60,
              batch_trigger_size    => 100,
              description           => \"Custom Description\",
              enabled               => false,
              home                  => \"/opt/aem/author\",
              log_level             => \"debug\",
              name                  => \"customname\",
              password              => \"admin\",
              protocol_close_conn   => true,
              protocol_conn_timeout => 1000,
              protocol_http_headers => [\"CQ-Action:{action}\", \"CQ-Handle:{path}\", \"CQ-Path:{path}\"],
              protocol_http_method  => \"POST\",
              protocol_interface    => \"127.0.0.1\",
              protocol_sock_timeout => 1000,
              protocol_version      => 1.0,
              proxy_host            => \"proxy.domain.com\",
              proxy_ntlm_domain     => \"proxydomain\",
              proxy_ntlm_host       => \"proxy.ntlm.domain.com\",
              proxy_password        => \"proxypassword\",
              proxy_port            => 12345,
              proxy_user            => \"proxyuser\",
              resource_type         => \"cq/replication/components/revagent\",
              retry_delay           => 60,
              reverse               => true,
              runmode               => \"custommode\",
              serialize_type        => \"flush\",
              static_directory      => \"/var/path\",
              static_definition     => \"/content/geo* \\${path}.html?wcmmode=preview\",
              template              => \"/libs/cq/replication/templates/revagent\",
              trans_allow_exp_cert  => true,
              trans_ntlm_domain     => \"transdomain\",
              trans_ntlm_host       => \"trans.ntlm.domain.com\",
              trans_password        => \"transpassword\",
              trans_ssl             => \"relaxed\",
              trans_uri             => \"http://localhost:4503/bin/receive?sling:authRequestLogin=1\",
              trans_user            => \"transuser\",
              trigger_ignore_def    => true,
              trigger_no_status     => false,
              trigger_no_version    => true,
              trigger_on_dist       => true,
              trigger_on_mod        => true,
              trigger_on_receive    => true,
              trigger_onoff_time    => true,
              username              => \"admin\"
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
        fqdn = fqdn.chop if fqdn.end_with?('.')

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
        cmd = 'curl http://localhost:4502/etc/replication/agents.custommode/customname.infinity.json '
        cmd += '-u admin:admin'
        shell(cmd) do |result|
          jsonresult = JSON.parse(result.stdout)

          expect(jsonresult['jcr:primaryType']).to eq('cq:Page')
          expect(jsonresult['jcr:content']['jcr:primaryType']).to eq('nt:unstructured')
          expect(jsonresult['jcr:content']['userId']).to eq('agentuser')
          expect(jsonresult['jcr:content']['queueBatchMode']).to eq(true)
          expect(jsonresult['jcr:content']['queueBatchWaitTime']).to eq(60)
          expect(jsonresult['jcr:content']['queueBatchMaxSize']).to eq(100)
          expect(jsonresult['jcr:content']['jcr:description']).to eq(desc)
          expect(jsonresult['jcr:content']['enabled']).to eq(false)
          expect(jsonresult['jcr:content']['logLevel']).to eq('debug')
          expect(jsonresult['jcr:content']['protocolHTTPConnectionClose']).to eq(true)
          expect(jsonresult['jcr:content']['protocolConenctTimeout']).to eq(1000)
          expect do
            jsonresult['jcr:content']['protocolHTTPHeaders']
          end.to eq(['CQ-Action:{action}', 'CQ-Handle:{path}', 'CQ-Path:{path}'])
          expect(jsonresult['jcr:content']['protocolHTTPMethod']).to eq('POST')
          expect(jsonresult['jcr:content']['protocolInterface']).to eq('127.0.0.1')
          expect(jsonresult['jcr:content']['protocolSocketTimeout']).to eq(1000)
          expect(jsonresult['jcr:content']['protocolVersion']).to eq(1.0)
          expect(jsonresult['jcr:content']['proxyHost']).to eq('proxy.domain.com')
          expect(jsonresult['jcr:content']['proxyNTLMDomain']).to eq('proxydomain')
          expect(jsonresult['jcr:content']['proxyNTLMHost']).to eq('proxy.ntlm.domain.com')
          expect(jsonresult['jcr:content']['proxyPassword']).to eq('proxypassword')
          expect(jsonresult['jcr:content']['proxyPort']).to eq(12_345)
          expect(jsonresult['jcr:content']['proxyUser']).to eq('proxyuser')
          expect(jsonresult['jcr:content']['sling:resourceType']).to eq('cq/replication/components/revagent')
          expect(jsonresult['jcr:content']['retryDelay']).to eq('60')
          expect(jsonresult['jcr:content']['reverseReplication']).to eq('true')
          expect(jsonresult['jcr:content']['serializationType']).to eq('flush')
          expect(jsonresult['jcr:content']['directory']).to eq('/var/path')
          expect(jsonresult['jcr:content']['definition']).to eq('/content/geo* ${path}.html?wcmmode=preview')
          expect(jsonresult['jcr:content']['cq:template']).to eq('/libs/cq/replication/templates/revagent')
          expect(jsonresult['jcr:content']['jcr:title']).to eq('Agent Title')
          expect(jsonresult['jcr:content']['proocolHTTPExpired']).to eq(true)
          expect(jsonresult['jcr:content']['transportNTLMDomain']).to eq('transdomain')
          expect(jsonresult['jcr:content']['transportNTLMHost']).to eq('trans.ntlm.domain.com')
          expect(jsonresult['jcr:content']['transportPassword']).to eq('transpassword')
          expect(jsonresult['jcr:content']['transportUri']).to eq('http://localhost:4503/bin/receive?sling:authRequestLogin=1')
          expect(jsonresult['jcr:content']['transportUser']).to eq('transuser')
          expect(jsonresult['jcr:content']['directory']).to eq('/var/path')
          expect(jsonresult['jcr:content']['ssl']).to eq('relaxed')
          expect(jsonresult['jcr:content']['triggerSpecific']).to eq(true)
          expect(jsonresult['jcr:content']['noStatusUdpate']).to eq(false)
          expect(jsonresult['jcr:content']['noVersioning']).to eq(true)
          expect(jsonresult['jcr:content']['triggerDistribute']).to eq(true)
          expect(jsonresult['jcr:content']['triggerDistribute']).to eq(true)
          expect(jsonresult['jcr:content']['triggerModified']).to eq(true)
          expect(jsonresult['jcr:content']['triggerReceive']).to eq(true)
          expect(jsonresult['jcr:content']['triggerOnOffTime']).to eq(true)

        end
      end
    end
  end

  describe 'aem::instance updated' do

    let(:facts) do
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
                shell('curl -I http://localhost:4503/aem-publish/') do |result|
                  if result.stdout =~ %r{HTTP\/1.1 (302|401|200)}
                    valid = true
                    throw :started if valid
                    break
                  end
                end
              rescue
                valid = false
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
