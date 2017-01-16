# AEM Instance

## Specify Type Example

You can specify the type of AEM installation to create. This is either `author` or `publish`. Once an instance is created, changing the definition will update the associated configuration script. However this update will have no impact on the operation of the AEM instance. (See [AEM documentation](https://docs.adobe.com/docs/en/aem/6-1/deploy/configuring/configure-runmodes.html#Installation Run Modes))

~~~ puppet
aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  type   => 'publish',
}
~~~

**AEM will be configured as defined in the [Minimal Example](/docs/aem-instance/Minimal.md), with the following changes:**

* Start in mode: *publish*
