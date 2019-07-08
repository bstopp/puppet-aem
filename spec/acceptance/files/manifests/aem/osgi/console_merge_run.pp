node 'agent' {

  $osgi = {
    'allow.hosts' => ['author.localhost'],
  }
  aem::osgi::config { 'org.apache.sling.security.impl.ReferrerFilter':
    ensure         => present,
    properties     => $osgi,
    handle_missing => 'merge',
    home           => '/opt/aem/author',
    password       => 'admin',
    type           => 'console',
    username       => 'admin',
  }
}