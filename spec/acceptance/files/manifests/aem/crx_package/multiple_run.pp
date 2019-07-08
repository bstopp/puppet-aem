node 'agent' {
      aem::crx::package { 'author-test-pkg' :
        ensure      => installed,
        home        => '/opt/aem/author',
        password    => 'admin',
        pkg_group   => 'my_packages',
        pkg_name    => 'test',
        pkg_version => '3.0.0',
        source      => '/vagrant/puppet/files/aem/test-3.0.0.zip',
        type        => 'api',
        username    => 'admin'
      }

      aem::crx::package { 'author-sescondtest-pkg' :
        ensure      => present,
        home        => '/opt/aem/author',
        password    => 'admin',
        pkg_group   => 'my_packages',
        pkg_name    => 'secondtest',
        pkg_version => '1.0.0',
        source      => '/vagrant/puppet/files/aem/secondtest-1.0.0.zip',
        type        => 'api',
        username    => 'admin'
      }
    }