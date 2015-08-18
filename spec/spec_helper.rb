require 'rubygems'
require 'rspec/mocks'
require 'puppetlabs_spec_helper/module_spec_helper'
require "codeclimate-test-reporter"


CodeClimate::TestReporter.start

RSpec.configure do |config|

  config.before :each do
    # Ensure that we don't accidentally cache facts and environment
    # between test cases.
    allow_any_instance_of(Facter::Util::Loader).to receive(:load_all)
    Facter.clear
    Facter.clear_messages
    
    # Store any environment variables away to be restored later
    @old_env = {}
    ENV.each_key {|k| @old_env[k] = ENV[k]}
 
    if ENV['STRICT_VARIABLES'] == 'yes'
      Puppet.settings[:strict_variables]=true
    end
  end

  config.mock_with :rspec
end

#shared_examples :compile, :compile => true do
#  it { should compile.with_all_deps }
#end