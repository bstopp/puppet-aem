require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'
require 'puppet-syntax/tasks/puppet-syntax'
require 'rake/clean'
require 'rubocop/rake_task'

exclude_paths = %w(
  vendor/**/*.pp
  spec/**/*.pp
  pkg/**/*.pp
)

disabled_checks = %w(
  80chars
  class_inherits_from_params_class
  class_parameter_defaults
  documentation
  single_quote_string_with_variables
  variable_scope
)

task default: [:spec, :lint, :rubocop]

PuppetLint::RakeTask.new :lint do |config|
  config.fail_on_warnings = true
  config.relative = true
  config.disable_checks = disabled_checks
  config.ignore_paths = exclude_paths
end

PuppetSyntax.exclude_paths = exclude_paths

CLEAN.include('coverage')
CLEAN.include('junit')
CLEAN.include('log')
CLEAN.include('.vagrant')
CLEAN.include('spec/fixtures')
CLEAN.include('spec/acceptance/logst')
