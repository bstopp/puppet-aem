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

      #puppet('resource aem') do |result|
      shell('puppet resource aem') do |result|
        group = /group[ ]*=>[ ]*'\S+'/.match(result.stdout).to_s
        user = /user[ ]*=>[ ]*'\S+'/.match(result.stdout).to_s
        version = /version[ ]*=>[ ]*'\S+'/.match(result.stdout).to_s
        home = /home[ ]*=>[ ]*'\S+'/.match(result.stdout).to_s

        group = /'\S+'/.match(group).to_s.gsub! '\'', ''
        user = /'\S+'/.match(user).to_s.gsub! '\'', ''
        version = /'\S+'/.match(version).to_s.gsub! '\'', ''
        home = /'\S+'/.match(home).to_s.gsub! '\'', ''

        expect(group).to match('root')
        expect(user).to match('root')
        expect(version).to match('6.1.0')
        expect(home).to match('/opt/aem')
      end

      

    end

  end
end