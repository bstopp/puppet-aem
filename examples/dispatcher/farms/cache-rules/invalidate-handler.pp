# Dispatcher Farm Cache Invalidate Handler Example

aem::dispatcher::farm { 'site' :
  docroot            => '/var/www',
  invalidate_handler => '/path/to/handler',
}
