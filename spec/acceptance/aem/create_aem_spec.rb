# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'create aem' do

  let(:facts) do
    {
      environment: :root
    }
  end

  context 'basic setup' do
    it 'should have unpacked the standalone jar' do
      shell('find /opt/aem/author/crx-quickstart -name "cq-quickstart-*-standalone*.jar" -type f') do |result|
        expect(result.stdout).to match(%r|^(\S+)/crx-quickstart/app/cq-quickstart-([0-9.]+)-standalone.*\.jar|)
      end
    end

    it 'should be owned by specified user/group' do
      shell('stat -c "%U:%G" /opt/aem/author/crx-quickstart/app/cq-quickstart*.jar') do |result|
        expect(result.stdout).to match('vagrant:vagrant')
      end
    end
  end

  context 'services running' do

    context service('aem-author') do
      it { should be_running }
      it { should be_enabled }
    end
  end

  context 'running instances' do
    it 'should start author with correct port and context root' do

      valid = false
      catch(:started) do
        Timeout.timeout(200) do
          Kernel.loop do
            begin
              shell('curl -I http://localhost:4502/') do |result|
                if result.stdout =~ %r{HTTP\/1.1 (302|401|200)}
                  valid = true
                  throw :started if valid
                  break
                end
              end
            rescue RuntimeError
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
