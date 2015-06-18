require 'spec_helper_acceptance'

describe 'Required Fields tests.', :unless => UNSUPPORTED_PLATFORMS.include?(fact('osfamily')) do

  before :need_home => :true do
    pp = <<-MANIFEST
      file { '/opt/aem' :
        ensure      => 'directory',
      }
    MANIFEST
    apply_manifest(pp, :catch_failures => true)
  end

  after :need_home => :true do
    pp = <<-MANIFEST
      file { '/opt/aem' :
        ensure      => 'absent',
        force       => 'true',
      }
    MANIFEST
    apply_manifest(pp, :catch_failures => true)
  end

  context 'home directory' do

    it 'Requires the home directory to exist' do
      pp = <<-MANIFEST
        aem { 'aem' :
          ensure      => 'present',
          version     => '6.1.0',
        }
      MANIFEST

      apply_manifest pp, :expect_failures => true do |result|
        expect( result.formatted_output() ).to match(/AEM home directory.*not found/)
      end

    end
  end

  context 'source parameter' do

    it 'Requires the source to be specified', :need_home => :true  do
      pp = <<-MANIFEST
        aem { 'aem' :
          ensure      => 'present',
          version     => '6.1.0',
          home        => '/opt/aem',
        }
      MANIFEST

      apply_manifest pp, :expect_failures => true do |result|
        expect( result.formatted_output() ).to match(/Source jar is required/)
      end
    end

  end
end