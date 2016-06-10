# Filters Farm Example


aem::dispatcher::farm { 'site' :
  docroot => '/var/www',
  filters => [
    {
      'rank' => 310,
      'type' => 'allow',
      'glob' => '*.html',
    },
    {
      'rank' => 300,
      'type' => 'deny',
      'glob' => '*',
    }
  ],
}
