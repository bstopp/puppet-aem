# Dispatcher Farm Retry Count Example

aem::dispatcher::farm { 'site' :
  docroot => '/var/www',
  retries => "5",
}
