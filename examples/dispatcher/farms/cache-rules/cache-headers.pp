# Dispatcher Farm Cache Headers Example

aem::dispatcher::farm { 'site' :
  docroot       => '/var/www/docroot',
  cache_headers => [
    'A-Cache-Header',
    'Another-Cache-Header'
  ],
}