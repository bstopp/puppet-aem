# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/fixtures/'
  add_filter '/spec/'
end

require 'rubygems'
require 'rspec/mocks'
require 'rspec-puppet'
require 'webmock/rspec'

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

RSpec.configure do |config|
  config.module_path = File.join(fixture_path, 'modules')
  config.manifest_dir = File.join(fixture_path, 'manifests')
  config.mock_with :rspec
  config.raise_errors_for_deprecations!

  config.before :each do
    # Ensure that we don't accidentally cache facts and environment
    # between test cases.
    allow_any_instance_of(Facter::Util::Loader).to receive(:load_all)
    Facter.clear
    Facter.clear_messages

    # Store any environment variables away to be restored later
    @old_env = {}
    ENV.each_key { |k| @old_env[k] = ENV[k] }

    Puppet.settings[:strict_variables] = true if ENV['STRICT_VARIABLES'] == 'yes'
  end

end

# require 'puppetlabs_spec_helper/module_spec_helper'

at_exit { RSpec::Puppet::Coverage.report! }
