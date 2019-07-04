node 'agent' {

  $osgi = {
    'allow.hosts' => ['author.localhost'],
  }
  aem::osgi::config { 'ReferrerFilter':
    ensure         => present,
    pid            => 'org.apache.sling.security.impl.ReferrerFilter',
    properties     => $osgi,
    handle_missing => 'remove',
    home           => '/opt/aem/author',
    password       => 'admin',
    type           => 'console',
    username       => 'admin',
  }
}