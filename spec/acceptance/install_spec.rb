require 'spec_helper_acceptance'

describe 'AEM Provider', :unless => UNSUPPORTED_PLATFORMS.include?(fact('osfamily')) do

  before :context do
    pp = <<-MANIFEST
      file { '/opt/aem' :
        ensure      => 'directory',
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

  context 'running puppet manifest' do

    it 'should work with no errors.' do
      pp = <<-MANIFEST
        aem { 'aem' :
          ensure      => 'present',
          version     => '6.1.0',
          home        => '/opt/aem',
          source      => '/var/aem-quickstart-4502.jar',
        }
      MANIFEST

      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

  end
end