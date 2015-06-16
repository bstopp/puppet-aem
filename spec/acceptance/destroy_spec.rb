require 'spec_helper_acceptance'

describe 'AEM Provider', :unless => UNSUPPORTED_PLATFORMS.include?(fact('osfamily')) do

  before :context do
    pp = <<-MANIFEST
      file { '/opt/aem' :
        ensure          => 'directory',
         
      }
      file { '/opt/aem/crx-quickstart' :
        ensure          => 'directory',
         
      }
      file { '/opt/aem/crx-quickstart/app' :
        ensure          => 'directory',
         
      }
      file { '/opt/aem/crx-quickstart/app/cq-quickstart-6.1.0-standalone.jar' :
        ensure        => 'file',
        content       => '',
      }
      file { '/opt/aem/faux' :
        ensure          => 'directory',
         
      }
      file { '/opt/aem/faux/crx-quickstart' :
        ensure          => 'directory',
         
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
      file { '/opt/aem' :
        ensure      => 'absent',
        force       => 'true',
      }
      
    MANIFEST
    apply_manifest(pp, :catch_failures => true)
  end

  context '#destroy' do

    it 'should work with no errors.' do
      pp = <<-MANIFEST
        aem { 'tobedeleted' :
          ensure      => 'absent',
          home        => '/opt/aem/faux',
        }
      MANIFEST

      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

    it 'should have deleted the crx-quickstart directory' do
      shell('test -d /opt/aem/faux/crx-quickstart', :acceptable_exit_codes => 1)
    end

    it 'should not have deleted the other installation' do
      shell('test -d /opt/aem/crx-quickstart', :acceptable_exit_codes => 0)
      shell('find /opt/aem/crx-quickstart -name "cq-quickstart-*-standalone*.jar" -type f') do |result|

        expect(result.stdout).to match(%r{^(\S+)/crx-quickstart/app/cq-quickstart-([0-9.]+)-standalone.*\.jar})
      end

    end

  end
end