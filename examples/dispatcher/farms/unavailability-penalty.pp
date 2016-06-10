# Dispatcher Farm Unavailablity Penalty Example

aem::dispatcher::farm { 'site' :
  docroot    => '/var/www',
  statistics => [
    {
      'glob'     => '*.html',
      'category' => 'html'
    },
    {
      'glob'     => '*',
      'category' => 'others'
    }
  ],
  unavailable_penalty => '2',
}
