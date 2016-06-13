
## Specific User/Group Example

This example shows how to customize the user/group which own the files in the installation. (Normal policies apply, see Puppet Provider _execute(*args)_ DSL definition.)

~~~ puppet
aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  user   => 'vagrant',
  group  => 'vagrant',
}
~~~

**AEM will be configured as defined in the [Minimal Example](/docs/aem-instance/Minimal.md), with the following changes:**

* Run using user/group: vagrant/vagrant

## Managing User/Group Example

By default, the AEM Module will manage the user/group specified in the resource definition. This can be disabled using the *manage_** attributes.

~~~ puppet
aem::instance { 'aem' :
  source       => '/path/to/aem-quickstart.jar',
  manage_group => false,
  manage_user  => false,
  user         => 'vagrant',
  group        => 'vagrant',
}
~~~

**AEM will be configured as defined in the [Minimal Example](/docs/aem-instance/Minimal.md), with the following changes:**

* Run using user/group: vagrant/vagrant
* The home directory be created and managed via Puppet; user and group will *not*.
