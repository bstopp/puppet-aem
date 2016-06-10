# Dispatcher Farm Cache Rules Serve Stale On Error Example

aem::dispatcher::farm { 'site' :
  docroot     => '/var/www',
  serve_stale => 1,
}