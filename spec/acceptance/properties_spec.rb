require 'spec_helper_acceptance'

describe 'property update', :unless => UNSUPPORTED_PLATFORMS.include?(fact('osfamily')) do

  before :context do
    env = <<-ENV
      PORT=4502
      TYPE=author
      RUNMODES=dev,mockup
      JVM_MEM_OPTS='-Xmx4096m -XX:MaxPermSize=1024M'
    ENV

    pp = <<-MANIFEST
      File { backup => false, }

      group { 'aem' : ensure => 'present' }

      user { 'aem' : ensure => 'present', gid =>  'aem' }

      file { '/opt/aem' :
        ensure      => 'directory',
        group       => 'aem',
        owner       => 'aem',
      }

      file { '/opt/aem/crx-quickstart' :
        ensure          => 'directory',
      }
      file { '/opt/aem/crx-quickstart/bin' :
        ensure        => 'directory',
      }
      file { '/opt/aem/crx-quickstart/bin/start-env' :
        ensure        => 'file',
        content       => "#{env}",
      }

      file { '/opt/aem/crx-quickstart/app' :
        ensure          => 'directory',
      }

      file { '/opt/aem/crx-quickstart/app/cq-quickstart-6.1.0-standalone.jar' :
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

  context 'version' do

    it 'should log a warning when updating' do

      pp = <<-MANIFEST
        File { backup => false, }

        aem { 'aem' :
          home          => '/opt/aem',
          ensure        => present,
          source        => '/tmp/aem-quickstart.jar',
          jvm_mem_opts  => '-Xmx4096m -XX:MaxPermSize=1024M',
          version       => '6.0.0',
        }
      MANIFEST

      apply_manifest pp, :catch_changes => true do |result|
        expect( result.formatted_output() ).to match(/Version cannot be modified after installation/)
      end
    end
  end

  context 'type' do

    it 'should log a warning when updating' do

      pp = <<-MANIFEST
        File { backup => false, }

        aem { 'aem' :
          home        => '/opt/aem',
          ensure      => present,
          source      => '/tmp/aem-quickstart.jar',
          jvm_mem_opts  => '-Xmx4096m -XX:MaxPermSize=1024M',
          type        => publish
        }
      MANIFEST

      apply_manifest pp, :catch_changes => true do |result|
        expect( result.formatted_output() ).to match(/Type cannot be modified after installation/)
      end
    end
  end

  context 'user' do

    it 'should log a warning when updating' do

      pp = <<-MANIFEST
        File { backup => false, }

        aem { 'aem' :
          home        => '/opt/aem',
          ensure      => present,
          source      => '/tmp/aem-quickstart.jar',
          jvm_mem_opts  => '-Xmx4096m -XX:MaxPermSize=1024M',
          user        => 'aem',
        }
      MANIFEST

      apply_manifest pp, :catch_changes => true do |result|
        expect( result.formatted_output() ).to match(/User cannot be modified after installation/)
      end
    end
  end

  context 'group' do

    it 'should log a warning when updating' do

      pp = <<-MANIFEST
        File { backup => false, }

        aem { 'aem' :
          home        => '/opt/aem',
          ensure      => present,
          source      => '/tmp/aem-quickstart.jar',
          jvm_mem_opts  => '-Xmx4096m -XX:MaxPermSize=1024M',
          group       => 'aem',
        }
      MANIFEST

      apply_manifest pp, :catch_changes => true do |result|
        expect( result.formatted_output() ).to match(/Group cannot be modified after installation/)
      end
    end
  end

  context 'runmodes' do
    
    it 'should update the start-env file with array' do
      pp = <<-MANIFEST
        File { backup => false, }

        aem { 'aem' :
          home        => '/opt/aem',
          ensure      => present,
          source      => '/tmp/aem-quickstart.jar',
          jvm_mem_opts  => '-Xmx4096m -XX:MaxPermSize=1024M',
          runmodes    => ['dev','client', 'server', 'mock'],
        }
      MANIFEST
      apply_manifest(pp, :expect_changes => true)
      shell("grep 'dev,client,server,mock' /opt/aem/crx-quickstart/bin/start-env", {:acceptable_exit_codes => 0})
    end

    it 'should update the start-env file with single value' do

      mode = 'production'

      pp = <<-MANIFEST
        File { backup => false, }

        aem { 'aem' :
          home        => '/opt/aem',
          ensure      => present,
          source      => '/tmp/aem-quickstart.jar',
          jvm_mem_opts  => '-Xmx4096m -XX:MaxPermSize=1024M',
          runmodes    => "#{mode}",
        }
      MANIFEST
      apply_manifest(pp, :expect_changes => true)
      shell("grep '#{mode}' /opt/aem/crx-quickstart/bin/start-env", {:acceptable_exit_codes => 0})
    end
  end

  context 'jvm_mem_opts' do

    it 'should update the start-env file' do

      opts = '-Xmx2048m -XX:MaxPermSize=512M'

      pp = <<-MANIFEST
        File { backup => false, }

        aem { 'aem' :
          home          => '/opt/aem',
          ensure        => present,
          source        => '/tmp/aem-quickstart.jar',
          jvm_mem_opts  => "#{opts}"
        }
      MANIFEST
      apply_manifest(pp, :expect_changes => true)
      shell("grep -- '#{opts}' /opt/aem/crx-quickstart/bin/start-env", {:acceptable_exit_codes => 0})
    end
  end
end