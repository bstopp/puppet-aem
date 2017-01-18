# CRX Package

## Console Examples

If **type** is set to *api*, the provider will use a API call to the CRX Package Manager to upload the package.

* [Upload Package](#upload)
* [Install Package](#install)
* [Remove Package](#remove)
* [Uninstall and Remove](#purge)


### Upload

The following will upload a package but not install it. If the package is already installed, this will uninstall but not remove it.

~~~ puppet
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
~~~

### Install

The following will upload and install the specified source package.

~~~ puppet
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
~~~

### Remove 

The following will remove the specified package from the package manager.

~~~puppet
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
~~~

### Purge 

The following will uninstall the package, then remove it from the Package Manager.

~~~puppet
aem::crx::package { 'author-test-pkg' :
  ensure      => purged,
  home        => '/opt/aem/author',
  password    => 'admin',
  pkg_group   => 'my_packages',
  pkg_name    => 'test',
  pkg_version => '1.0.0',
  type        => 'api',
  username    => 'admin'
}
~~~
