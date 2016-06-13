# Dispatcher Farm Cache Stat Files Level Example

aem::dispatcher::farm { 'site' :
  docroot          => '/var/www',
  stat_files_level => 3,
}
