The service can be managed as a separate resource and has different states.

* [Unmanaged](#unmanaged-service)
* [Disabled](#disabled-service)
* [Running](#running-service)


## Unmanaged Service

By default a Puppet service will be created and started for AEM. You can disable this entirely:

~~~ puppet
aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  service => 'unmanaged'
}
~~~

**AEM will be configured as defined in the [Minimal Example](/docs/aem-instance/Minimal.md), with the following changes:**

* No Puppet service resource will be created, and it's running state will not be changed.

## Disabled Service Example

You can also ensure AEM Service is not running, and not enabled it on boot:

~~~ puppet
aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  service => 'disabled'
}
~~~

**AEM will be configured as defined in the [Minimal Example](/docs/aem-instance/Minimal.md), with the following changes:**

* A Puppet service resource will be created, but it'll be disabled and not running.

## Running Service Example

AEM can be running, but not enabled on boot:

~~~ puppet
aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  service => 'running'
}
~~~

**AEM will be configured as defined in the [Minimal Example](/docs/aem-instance/Minimal.md), with the following changes:**

* A Puppet service resource will be created, but it'll be disabled (not running on boot), but currently running.
