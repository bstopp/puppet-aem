require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-syntax/tasks/puppet-syntax'
require 'rubocop/rake_task'

exclude_paths = [
  'spec/**/*'
]

task :default => [:spec, :lint, :rubocop]

PuppetLint.configuration.fail_on_warnings = true
PuppetLint.configuration.send('relative')
PuppetLint.configuration.send('disable_80chars')
#PuppetLint.configuration.send('disable_documentation')
PuppetLint.configuration.send('disable_variable_scope')
#PuppetLint.configuration.send('disable_single_quote_string_with_variables')


PuppetLint.configuration.ignore_paths = exclude_paths
PuppetSyntax.exclude_paths = exclude_paths

RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = ['lib/**/*.rb']
end
