require 'spec_helper_acceptance'

describe 'aem::instance' do

  before(:all) do
    setup_puppet default
  end

  describe 'aem::instance first run' do

    let :facts do
      {
        :environment => :root
      }
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
              source          => \"/tmp/aem-quickstart.jar\",
              home            => \"/opt/aem/author\",
              user            => \"vagrant\",
              group           => \"vagrant\",
              jvm_mem_opts    => \"-Xmx2048m\",
              osgi_configs    => \$osgi,
              timeout         => 1200,
            }

            Class[\"java\"] -> File[\"/opt/aem\"] -> Aem::Instance <| |>

            Aem::License {
              customer    => \"Vagrant Test\",
              license_key => \"fake-key-for-testing\",
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

        with_puppet_running_on(master, server_opts, master.tmpdir('puppet')) do
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
          shell('grep "license.downloadID=fake-key-for-testing" /opt/aem/author/license.properties',
                :acceptable_exit_codes => 0)
        end

        it 'should contain version' do
          shell('grep "license.product.version=6.1.0" /opt/aem/author/license.properties',
                :acceptable_exit_codes => 0)
        end
      end

    end

#    context 'osgi configs' do
#      it 'should contain osgi config file' do
#
#        valid = false
#        shell('curl -I http://localhost:4502/') do |result|
#          valid = result.stdout =~ %r{HTTP\/1.1 302 Found}
#        end
#        expect(valid).to eq(true)
#      end
#    end

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
                  if result.stdout =~ %r{HTTP\/1.1 302 Found}
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
        with_puppet_running_on(master, server_opts, master.tmpdir('puppet')) do
          fqdn = on(master, 'facter fqdn').stdout.strip
          on(
            default,
            puppet("agent --detailed-exitcodes --onetime --no-daemonize --verbose --server #{fqdn}"),
            :acceptable_exit_codes => [0, 2]
          )
        end
      end
    end

    context 'create' do
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
        with_puppet_running_on(master, server_opts, master.tmpdir('puppet')) do
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
                  if result.stdout =~ %r{HTTP\/1.1 302 Found}
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
