node 'agent' {

  aem_sling_resource { 'test node':
    ensure   => absent,
    path     => '/content/testnode',
    home     => '/opt/aem/author',
    password => 'admin',
    username => 'admin',
  }

}