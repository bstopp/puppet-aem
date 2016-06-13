# Dispatcher Farm Statistics Farm Example

aem::dispatcher::farm { 'site' :
  docroot    => '/var/www',
  statistics => [
    {
      'rank'     => 310,
      'glob'     => '*',
      'category' => 'others'
    },
    {
      'rank'     => 300,
      'glob'     => '*.html',
      'category' => 'html'
    }
  ],
}