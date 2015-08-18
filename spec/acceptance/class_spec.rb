require 'spec_helper_acceptance'

describe 'apache class', :unless => UNSUPPORTED_PLATFORMS.include?(fact('osfamily')) do
  
  context 'default parameters' do

    it 'should work with no errors' do
      pp = <<-EOS
      class { "aem":
        source  => "/tmp/aem-quickstart.jar"
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

  end
end