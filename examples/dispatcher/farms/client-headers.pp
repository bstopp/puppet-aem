# Client Headers Farm Example

aem::dispatcher::farm { 'site' :
  docroot        => '/var/www',
  client_headers => [
    'A-Client-Header',
    'Another-Client-Header'
  ],
}