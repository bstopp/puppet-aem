# Dispatcher Cache Rules Statfile Example

aem::dispatcher::farm { 'site' :
  docroot   => '/var/www',
  stat_file => '/path/to/statfile',
}