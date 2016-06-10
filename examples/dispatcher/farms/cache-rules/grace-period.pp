# Dispatcher Farm Cache Grace Period Example

aem::dispatcher::farm { 'site' :
  docroot      => '/var/www/docroot',
  grace_period => '1',
}
