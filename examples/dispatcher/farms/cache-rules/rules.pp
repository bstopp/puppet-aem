# Dispatcher Farm Cache Rules Example

aem::dispatcher::farm { 'site' :
  docroot     => '/var/www',
  cache_rules => [
    {
      'rank' => 310,
      'glob' => '*.html',
      'type' => 'allow'
    },
    {
      'rank' => 300,
      'glob' => '*',
      'type' => 'deny'
    }
  ],
}
