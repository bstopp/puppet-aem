# Renderers Farm Example

# Single Renderer

aem::dispatcher::farm { 'site' :
  docroot => '/var/www',
  renders => {
    'hostname'       => 'publish.hostname.com',
    'port'           => 8080,
    'timeout'        => 600,
    'receiveTimeout' => 300,
    'ipv4'           => 0,
  },
}


# Multiple Renderers

aem::dispatcher::farm { 'site' :
  docroot => '/var/www',
  renders => [
    {
      'hostname'       => 'publish.hostname.com',
      'port'           => 8080,
      'timeout'        => 600,
      'receiveTimeout' => 300,
      'ipv4'           => 0,
    },
    {
      'hostname' => 'author.hostname.com',
      'port'     => 9009,
    }
  ]
}