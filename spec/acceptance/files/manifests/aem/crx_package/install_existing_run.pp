node 'agent' {
  aem::crx::package { 'author-test-pkg':
    ensure      => installed,
    home        => '/opt/aem/author',
    password    => 'admin',
    pkg_group   => 'my_packages',
    pkg_name    => 'test',
    pkg_version => '2.0.0',
    source      => '/vagrant/puppet/files/aem/test-2.0.0.zip',
    type        => 'api',
    username    => 'admin'
  }
}