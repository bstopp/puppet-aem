# Virtual Hosts Farm Example

aem::dispatcher::farm { 'site' :
  docroot      => '/var/www',
  virtualhosts => [
    'www.avirtualhost.com',
    'another.virtual.com'
  ],
}