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

    let(:resource_line) do
      /(\S+)\s*=>\s*'?(\S+?)'?,/
    end

    it 'lists the instances' do

      shell('puppet resource aem') do |result|

        data = {}

        result.stdout.each_line do |line|
          if match = resource_line.match(line)

            data[match[1]] = match[2]
          end
        end

        expect(data['group']).to match('root')
        expect(data['user']).to match('root')
        expect(data['version']).to match('6.1.0')
        expect(data['home']).to match('/opt/aem')

      end

    end

  end
end