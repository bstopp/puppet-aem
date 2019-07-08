node 'agent' {

  $osgi = {
    'allow.empty'    => true,
    'allow.hosts'    => ['author.localhost.localmachine'],
    'filter.methods' => ['POST', 'PUT', 'DELETE', 'TRACE'],
  }
  aem::osgi::config { 'org.apache.sling.security.impl.ReferrerFilter':
    ensure         => present,
    properties     => $osgi,
    handle_missing => 'remove',
    home           => '/opt/aem/author',
    password       => 'admin',
    type           => 'console',
    username       => 'admin',
  }
}