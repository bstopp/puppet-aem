
# Dispatcher Farm Enable TTL Example

aem::dispatcher::farm { 'site' :
  docroot   => '/var/www/docroot',
  cache_ttl => '1',
}