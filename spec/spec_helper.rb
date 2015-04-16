require 'rubygems'
require 'rspec/mocks'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'coveralls'

RSpec.configure do |config|
  config.mock_with :rspec
end
Coveralls.wear!
