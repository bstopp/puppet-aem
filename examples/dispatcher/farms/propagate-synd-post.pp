# Propagate Synd Post Farm Example

aem::dispatcher::farm { 'site' :
  docroot             => '/var/www',
  propagate_synd_post => '1',
}
