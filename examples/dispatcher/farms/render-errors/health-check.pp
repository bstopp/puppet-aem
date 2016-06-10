# Dispatcher Farm Health Check Example

aem::dispatcher::farm { 'site' :
  docroot          => '/var/www',
  health_check_url => '/path/to/healthcheck',
}
