# CRX Package

## CRX Package: File Type Example

If the **type** is set to *file*, the source package will be copied to the *<home>/crx-quickstart/install* folder.

This example sets copies the *test.zip* package to the appropriate folder. 

~~~ puppet
aem::crx::package { 'author-test-pkg' :
  ensure => present,
  group  => 'aem',
  home   => '/opt/aem',
  source => '/path/to/file.zip',
  user   => 'aem'
}
~~~
