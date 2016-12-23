source ENV['GEM_SOURCE'] || 'https://rubygems.org'

group :development, :tests do
  gem 'rspec',                     require: false
  gem 'rake',                      require: false
  gem 'metadata-json-lint',        require: false
  gem 'rspec-puppet',              require: false
  gem 'webmock',                   require: false
  gem 'puppetlabs_spec_helper',    require: false
  gem 'codeclimate-test-reporter', require: false
end

group :linting do
  gem 'puppet-lint',                require: false
  gem 'rubocop',                    require: false
end

group :system_tests do
  gem 'beaker',                       require: false
  gem 'beaker-rspec',                 require: false
  gem 'serverspec',                   require: false
  gem 'beaker-puppet_install_helper', require: false
end

if facterversion = ENV['FACTER_GEM_VERSION']
  gem 'facter', facterversion, require: false
else
  gem 'facter', require: false
end

if puppetversion = ENV['PUPPET_VERSION']
  gem 'puppet', puppetversion, require: false
else
  gem 'puppet', require: false
end

gem 'crx_packmgr_api_client', '>=1.1.0', require: false
gem 'xml-simple',             '>=1.1.5', require: false
