# Vanity URLs Farm Example

aem::dispatcher::farm { 'site' :
  docroot     => '/var/www',
  vanity_urls => {
    'file'  => '/path/to/cache',
    'delay' => 600,
  },
}