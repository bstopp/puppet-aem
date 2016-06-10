# Dispatcher Farm Cache Allowed Clients Example

aem::dispatcher::farm { 'site' :
  docroot         => '/var/www',
  allowed_clients => [
    {
      'rank' => 310,
      'type' => 'allow',
      'glob' => '127.0.0.1'
    },
    {
      'rank' => 300,
      'type' => 'deny',
      'glob' => '*'
    },
  ],
}