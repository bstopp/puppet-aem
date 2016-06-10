# Dispatcher Farm Retry Delay Example

aem::dispatcher::farm { 'site' :
  docroot     => '/var/www',
  retry_delay => '30',
}
