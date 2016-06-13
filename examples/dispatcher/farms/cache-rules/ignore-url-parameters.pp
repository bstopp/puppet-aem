# Dispatcher Farm Cache Ignore URL Parameters Example

aem::dispatcher::farm { 'site' :
  docroot           => '/var/www',
  ignore_parameters => [
    {
      'rank' => 310,
      'glob' => 'param=*',
      'type' => 'allow'
    },
    {
      'rank' => 300,
      'glob' => '*',
      'type' => 'deny'
    },
  ],
}