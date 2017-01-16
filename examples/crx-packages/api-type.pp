# API CRX Package

# Upload and Install Package

aem::crx::package { 'author-test-pkg' :
  ensure      => installed,
  home        => '/opt/aem/author',
  password    => 'admin',
  pkg_group   => 'my_packages',
  pkg_name    => 'test',
  pkg_version => '1.0.0',
  source      => '/tmp/test-1.0.0.zip',
  type        => 'api',
  username    => 'admin'
}

# Upload but do not install package
# Or Uninstall an installed package

aem::crx::package { 'author-test-pkg' :
  ensure      => present,
  home        => '/opt/aem/author',
  password    => 'admin',
  pkg_group   => 'my_packages',
  pkg_name    => 'test',
  pkg_version => '1.0.0',
  source      => '/tmp/test-1.0.0.zip',
  type        => 'api',
  username    => 'admin'
}

# Remove Installed package

aem::crx::package { 'author-test-pkg' :
  ensure      => absent,
  home        => '/opt/aem/author',
  password    => 'admin',
  pkg_group   => 'my_packages',
  pkg_name    => 'test',
  pkg_version => '1.0.0',
  type        => 'api',
  username    => 'admin'
}