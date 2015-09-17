require 'spec_helper_acceptance'

describe 'aem::instance' do

  before(:all) do

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

  file { \"/opt/faux/crx-quickstart/bin/start\" :
    ensure        => \"file\",
    source       => "puppet:///modules/aem/start",
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

  aem::instance { \"author\" :
    source          => \"/tmp/aem-quickstart.jar\",
    home            => \"/opt/aem/author\",
    user            => \"vagrant\",
    group           => \"vagrant\",
    jvm_mem_opts    => \"-Xmx2048m\",
  }

  aem::instance { \"publish\" :
    source          => \"/tmp/aem-quickstart.jar\",
    home            => \"/opt/aem/publish\",
    manage_home     => false,
    manage_user     => false,
    manage_group    => false,
    jvm_opts        => \"-XX:+UseParNewGC\",
    jvm_mem_opts    => \"-Xmx2048m -XX:MaxPermSize=512M\",
    sample_content  => false,
    type            => \"publish\",
    port            => 4503,
    debug_port      => 54321,
    context_root    => \"aem-publish\",
    runmodes    => [\"dev\", \"client\", \"server\", \"mock\"],
  }

  Class[\"java\"] -> File[\"/opt/aem\"] -> Aem::Instance <| |>

  file { \"/opt/aem/publish\" :
    ensure          => \"directory\",
  }

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

  aem::license { \"publish\" :
    home    => \"/opt/aem/publish\",
  }

  Aem::Instance[\"author\"] -> Aem::License[\"author\"]
  Aem::Instance[\"publish\"] -> Aem::License[\"publish\"]

}'

    MANIFEST

    setup_puppet default
    pp = <<-MANIFEST
      file {
        '#{master.puppet['codedir']}/environments/production/manifests/site.pp':
          ensure => file,
          content => #{site}
      }
    MANIFEST

    apply_manifest_on(master, pp, :catch_failures => true)
  end

  describe 'aem::instance' do

    let :facts do
      {
        :environment => :root
      }
    end

    context 'create' do
      it 'should work with no errors' do
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

      it 'should have unpacked the standalone jar' do
        shell('find /opt/aem/author/crx-quickstart -name "cq-quickstart-*-standalone*.jar" -type f') do |result|
          expect(result.stdout).to match(%r{^(\S+)/crx-quickstart/app/cq-quickstart-([0-9.]+)-standalone.*\.jar})
        end
        shell('find /opt/aem/publish/crx-quickstart -name "cq-quickstart-*-standalone*.jar" -type f') do |result|
          expect(result.stdout).to match(%r{^(\S+)/crx-quickstart/app/cq-quickstart-([0-9.]+)-standalone.*\.jar})
        end
      end

      it 'should be owned by specified user/group' do
        shell('stat -c "%U:%G" /opt/aem/author/crx-quickstart/app/cq-quickstart*.jar') do |result|
          expect(result.stdout).to match('vagrant:vagrant')
        end
        shell('stat -c "%U:%G" /opt/aem/publish/crx-quickstart/app/cq-quickstart*.jar') do |result|
          expect(result.stdout).to match('aem:aem')
        end
      end

    end

    context 'start-env config' do
      it 'should update the type' do
        shell("grep TYPE=\\'author\\' /opt/aem/author/crx-quickstart/bin/start-env", :acceptable_exit_codes => 0)
        shell("grep TYPE=\\'publish\\' /opt/aem/publish/crx-quickstart/bin/start-env", :acceptable_exit_codes => 0)
      end

      it 'should update the port' do
        shell('grep PORT=4502 /opt/aem/author/crx-quickstart/bin/start-env', :acceptable_exit_codes => 0)
        shell('grep PORT=4503 /opt/aem/publish/crx-quickstart/bin/start-env', :acceptable_exit_codes => 0)
      end

      it 'should update the runmodes' do
        shell("grep RUNMODES=\\'dev,client,server,mock\\' /opt/aem/publish/crx-quickstart/bin/start-env",
              :acceptable_exit_codes => 0)
      end

      it 'should update the sample content' do
        shell("grep SAMPLE_CONTENT=\\'\\' /opt/aem/author/crx-quickstart/bin/start-env",
              :acceptable_exit_codes => 0)
        shell("grep SAMPLE_CONTENT=\\'nosamplecontent\\' /opt/aem/publish/crx-quickstart/bin/start-env",
              :acceptable_exit_codes => 0)
      end

      it 'should update the debug port' do
        shell("grep -- 'DEBUG_PORT=54321' /opt/aem/publish/crx-quickstart/bin/start-env", :acceptable_exit_codes => 0)
      end

      it 'should update the context root' do
        shell('grep CONTEXT_ROOT /opt/aem/author/crx-quickstart/bin/start-env', :acceptable_exit_codes => 1)
        shell("grep CONTEXT_ROOT=\\'aem-publish\\' /opt/aem/publish/crx-quickstart/bin/start-env",
              :acceptable_exit_codes => 0)
      end

      it 'should update the jvm memory settings' do
        shell("grep -- \"JVM_MEM_OPTS='-Xmx2048m -XX:MaxPermSize=512M'\" /opt/aem/publish/crx-quickstart/bin/start-env",
              :acceptable_exit_codes => 0)
      end

      it 'should update the jvm settings' do
        shell("grep -- JVM_OPTS=\\'-XX:+UseParNewGC\\' /opt/aem/publish/crx-quickstart/bin/start-env",
              :acceptable_exit_codes => 0)
      end
    end

    context 'license' do
      context 'author' do 
        it 'should have license file' do
          shell("test -f /opt/aem/publish/license.properties", :acceptable_exit_codes => 0)
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
          shell('grep "license.product.version=6.1.0" /opt/aem/publish/license.properties',
                :acceptable_exit_codes => 0)
        end
      end

      context 'publish' do 
        it 'should have license file' do
          shell("test -f /opt/aem/publish/license.properties", :acceptable_exit_codes => 0)
        end

        it 'should have correct owner:group' do
          shell('stat -c "%U:%G" /opt/aem/publish/license.properties') do |result|
            expect(result.stdout).to match('aem:aem')
          end
        end

        it 'should contain customer' do
          shell('grep "license.customer.name=Vagrant Test" /opt/aem/publish/license.properties',
                :acceptable_exit_codes => 0)
        end

        it 'should contain licnese_key' do
          shell('grep "license.downloadID=fake-key-for-testing" /opt/aem/publish/license.properties',
                :acceptable_exit_codes => 0)
        end

        it 'should contain version' do
          shell('grep "license.product.version=6.1.0" /opt/aem/publish/license.properties',
                :acceptable_exit_codes => 0)
        end
      end
    end

    context 'running instances' do
      it 'should start author with correct port and context root' do
        shell('sudo -u vagrant -g vagrant /opt/aem/author/crx-quickstart/bin/start')
        shell('sudo -u aem -g aem /opt/aem/publish/crx-quickstart/bin/start')

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

        shell('sudo -u vagrant -g vagrant /opt/aem/author/crx-quickstart/bin/stop')
        shell('sudo -u aem -g aem /opt/aem/publish/crx-quickstart/bin/stop')

      end
    end

    context 'destroy' do
      site = <<-MANIFEST
      'node \"agent\" {
        File { backup => false, owner => \"aem\", group => \"aem\" }

        aem::instance { \"author\" :
          ensure       => absent,
          manage_user  => false,
          manage_group => false,
          user         => \"vagrant\",
          group        => \"vagrant\",
          home         => \"/opt/aem/author\",
        }
        aem::instance { \"publish\" :
          ensure      => absent,
          home        => \"/opt/aem/publish\",
          manage_home => false,
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

      it 'should work with no errors' do
        apply_manifest_on(master, pp, :catch_failures => true)
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

      it 'should have removed author entirely' do
        shell('ls /opt/aem/author', :acceptable_exit_codes => 2)
      end

      it 'should have removed publish repository' do
        shell('ls /opt/aem/publish/crx-quickstart', :acceptable_exit_codes => 2)
        shell('ls /opt/aem/publish', :acceptable_exit_codes => 0)
      end
    end
  end
end
