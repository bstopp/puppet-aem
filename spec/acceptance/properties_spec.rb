require 'spec_helper_acceptance'

describe 'property update', :unless => UNSUPPORTED_PLATFORMS.include?(fact('osfamily')) do

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

      file { '/opt/aem/crx-quickstart' :
        ensure          => 'directory',
      }
      file { '/opt/aem/crx-quickstart/bin' :
        ensure        => 'directory',
      }
      file { '/opt/aem/crx-quickstart/bin/start-env' :
        ensure        => 'file',
        content       => "PORT=4502\nTYPE=author",
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
          home        => '/opt/aem',
          ensure      => present,
          source      => '/tmp/aem-quickstart.jar',
          version     => '6.0.0',
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
          runmodes    => ['dev','client', 'server', 'mock'],
        }
      MANIFEST
      apply_manifest(pp, :expect_changes => true)
      shell("grep 'dev,client,server,mock' /opt/aem/crx-quickstart/bin/start-env", {:acceptable_exit_codes => 0})
    end

    it 'should update the start-env file with single value' do
      pp = <<-MANIFEST
        File { backup => false, }

        aem { 'aem' :
          home        => '/opt/aem',
          ensure      => present,
          source      => '/tmp/aem-quickstart.jar',
          runmodes    => 'production',
        }
      MANIFEST
      apply_manifest(pp, :expect_changes => true)
      shell("grep 'production' /opt/aem/crx-quickstart/bin/start-env", {:acceptable_exit_codes => 0})
    end
  end

end