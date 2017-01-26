# CRX Package

## Notes

The group (_pkg_group_), name (_pkg_name_), and version (_pkg_version_) resource properties need to match exactly what you would find in the package. If these values do not match, Puppet may reinstall the package on each run, as it will not be able to identify that the package is installed.

This information can be found inside the packages, in the `META-INF/properties.xml` file. Or, as this image shows, in the CRX Package Manager UI.

![crx-package](docs/crx-package/crx-package.png)

## API Examples

If **type** is set to *api*, the provider will use a API call to the CRX Package Manager to upload the package.

* [Upload/Uninstall Package](#upload)
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
