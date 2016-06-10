
## Specific Home Directory Example

This example shows how to customize the home directory in which AEM will be installed. (Normal policies apply, see Puppet Provider _execute(*args)_ DSL definition.)

~~~ puppet
aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  home   => '/opt/aem/author',
}
~~~

**AEM will be configured as defined in the [Minimal Example](docs/aem-instance/Minimal.md), with the following changes:**

* Installed in: /opt/aem/author

## Managing Home Directory Example

By default, the AEM Module will manage the home directory specified in the resource definition. This can be disabled using the *manage_** attributes.

~~~ puppet
aem::instance { 'aem' :
  source      => '/path/to/aem-quickstart.jar',
  home        => '/opt/aem/author',
  manage_home => false,
}
~~~

**AEM will be configured as defined in the [Minimal Example](docs/aem-instance/Minimal.md), with the following changes:**

* Installed in: /opt/aem/author
* The user and group will all be created and managed via Puppet, the home directory will *not*.
