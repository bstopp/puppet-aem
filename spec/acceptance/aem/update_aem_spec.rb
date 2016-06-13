require 'spec_helper_acceptance'

describe 'updated aem settings' do

  let(:facts) do
    {
      :environment => :root
    }
  end

  include_examples 'setup aem'
  include_examples 'update aem'

  context 'services running in new state' do

    describe service('aem-author') do
      it { should_not be_enabled }
      it { should be_running }
    end

  end

  context 'running instances' do
    it 'should have restarted correct port and context root' do

      valid = false
      catch(:started) do
        Timeout.timeout(200) do
          Kernel.loop do

            begin
              shell('curl -I http://localhost:4503/aem-publish/') do |result|
                if result.stdout =~ %r{HTTP\/1.1 (302|401|200)}
                  valid = true
                  throw :started if valid
                  break
                end
              end
            rescue
              valid = false
            end
            sleep 15
          end
        end
      end
      expect(valid).to eq(true)
    end
  end
end
