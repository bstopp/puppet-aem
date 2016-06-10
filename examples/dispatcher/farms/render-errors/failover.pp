# Dispatcher Farm Failover Example

aem::dispatcher::farm { 'site' :
  docroot  => '/var/www',
  failover => 1,
}
