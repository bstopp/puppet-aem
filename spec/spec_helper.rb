require 'rubygems'
require 'rspec/mocks'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'coveralls'
require "codeclimate-test-reporter"


CodeClimate::TestReporter.start
Coveralls.wear!

RSpec.configure do |config|
  config.mock_with :rspec
end
