node 'agent' {

  aem::osgi::config { 'org.apache.sling.security.impl.ReferrerFilter':
    ensure   => absent,
    home     => '/opt/aem/author',
    password => 'admin',
    type     => 'console',
    username => 'admin',
  }
}