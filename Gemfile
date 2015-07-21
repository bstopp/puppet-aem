source ENV['GEM_SOURCE'] || 'https://rubygems.org'

group :development, :tests do
  gem 'rspec',  '~> 3.3',       :require => false
  gem 'rake',                   :require => false
  gem 'metadata-json-lint',     :require => false
  gem 'rspec-puppet',           :require => false
  gem 'puppetlabs_spec_helper', :require => false
end

group :linting do
  gem 'coveralls',              :require => false
  gem 'puppet-lint',            :require => false
  gem 'rubocop',                :require => false
end

group :system_tests do
  gem 'beaker', '~>2.18',               :require => false
  gem 'beaker-rspec',                   :require => false
  gem 'serverspec',                     :require => false
  gem 'beaker-puppet_install_helper', '>= 0.2.1', :require => false
end

if facterversion = ENV['FACTER_GEM_VERSION']
  gem 'facter', facterversion, :require => false
else
  gem 'facter', :require => false
end

if puppetversion = ENV['PUPPET_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end
