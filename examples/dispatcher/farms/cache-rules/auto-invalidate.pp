# Dispatcher Farm Cache Auto Invalidate Example

aem::dispatcher::farm { 'site' :
  docroot    => '/var/www',
  invalidate => [
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