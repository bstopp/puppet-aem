# Dispatcher Farm Sticky Connections Examples

#  Single Path Example

aem::dispatcher::farm { 'site' :
  docroot            => '/var/www',
  sticky_connections => '/path/to/content',
}

# Multiple Paths Example

aem::dispatcher::farm { 'site' :
  docroot            => '/var/www',
  sticky_connections => [
    '/path/to/content',
    '/another/path/to/content'
  ]
}
