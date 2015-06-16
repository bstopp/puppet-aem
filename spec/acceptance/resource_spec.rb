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
      file { '/opt/aem/crx-quickstart/apps' :
        ensure          => 'directory',
         
      }
      file { '/opt/aem/crx-quickstart/apps/cq-quickstart-6.1.0-standalone.jar' :
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

  context 'puppet resource' do

    it 'lists the instances' do

      puppet('resource aem') do |result|
        puts result
      end

    end

  end
end