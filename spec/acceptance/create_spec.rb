require 'spec_helper_acceptance'

describe 'AEM Provider', :unless => UNSUPPORTED_PLATFORMS.include?(fact('osfamily')) do

  before :context do
    pp = <<-MANIFEST
      File { backup => false, }

      group { 'aem' : ensure => 'present' }

      user { 'aem' : ensure => 'present', gid =>  'aem' }

      file { '/opt/aem' :
        ensure      => 'directory',
        group       => 'aem',
        owner       => 'aem',
      }

      file { '/opt/aem/faux' :
        ensure          => 'directory',
      }

      file { '/opt/aem/faux/crx-quickstart' :
        ensure          => 'directory',
      }
      file { '/opt/aem/faux/crx-quickstart/bin' :
        ensure        => 'directory',
      }
      file { '/opt/aem/faux/crx-quickstart/bin/start-env' :
        ensure        => 'file',
        content       => "PORT=4502\nTYPE=author",
      }

      file { '/opt/aem/faux/crx-quickstart/app' :
        ensure          => 'directory',
      }

      file { '/opt/aem/faux/crx-quickstart/app/cq-quickstart-6.1.0-standalone.jar' :
        ensure        => 'file',
        content       => '',
      }
    MANIFEST
    apply_manifest(pp, :catch_failures => true)
  end

  after :context do
    pp = <<-MANIFEST
      File { backup => false, }
      file { '/opt/aem' :
        ensure      => 'absent',
        force       => 'true',
      }
    MANIFEST
    apply_manifest(pp, :catch_failures => true)
  end

  context '#create' do

    let :facts do
      {
        :environment => :root
      }
    end

    it 'should work with no errors' do
      pp = <<-MANIFEST
        File { backup => false, }

        aem { 'aem' :
          ensure      => present,
          source      => '/tmp/aem-quickstart.jar',
          home        => '/opt/aem',
          user        => 'aem',
          group       => 'aem',
        }
      MANIFEST

      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

    it 'should have unpacked the standalone jar' do
      shell('find /opt/aem/crx-quickstart -name "cq-quickstart-*-standalone*.jar" -type f') do |result|
        expect(result.stdout).to match(%r{^(\S+)/crx-quickstart/app/cq-quickstart-([0-9.]+)-standalone.*\.jar})
      end
    end

    it 'should be owned by specified user/group' do
      shell('stat -c "%U:%G" /opt/aem/crx-quickstart/app/cq-quickstart*.jar') do |result|
        expect(result.stdout).to match('aem:aem')
      end
    end

    it 'should not change existing install' do
      pp = <<-MANIFEST
        File { backup => false, }

        aem { 'existing' :
          ensure      => 'present',
          version     => '6.1.0',
          home        => '/opt/aem/faux',
          source      => '/tmp/aem-quickstart.jar',
        }
      MANIFEST

      apply_manifest(pp, :catch_changes => true)
    end

  end
end