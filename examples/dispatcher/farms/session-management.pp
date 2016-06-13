# Session Management Farm Example

aem::dispatcher::farm { 'site' :
  docroot => '/var/www',
  session_management  => {
    'directory' => '/path/to/cache',
    'encode'    => 'md5',
    'header'    => 'HTTP:authorization',
    'timeout'   => 1000
  },
}
