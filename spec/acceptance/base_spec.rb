require 'spec_helper_acceptance'

describe 'base test', :unless => UNSUPPORTED_PLATFORMS.include?(fact('osfamily')) do

  context 'test' do

    it 'should work with no errors' do
      pp = <<-EOS
        $myuser = {
        'testuser' => { 'shell' => '/bin/bash' }
      }

      homes { 'testuser':
        user => $myuser
      }
      EOS

      apply_manifest(pp, :catch_failures => true)
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
   end

   describe user('testuser') do
     it { should exist }
   end

   describe file('/home/testuser') do
     it { should be_directory }
   end
 end

end