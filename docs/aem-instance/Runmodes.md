# AEM Instance

## Specify runmodes Example

You can specify additional runmodes for the AEM instance. See notes on *runmodes* usage with respect to *type* and *sample_content*. (See [AEM documentation](https://docs.adobe.com/docs/en/aem/6-1/deploy/configuring/configure-runmodes.html#Customized Run Modes))

~~~ puppet
aem::instance { 'aem' :
  source   => '/path/to/aem-quickstart.jar',
  runmodes => ['dev', 'server', 'mock'],
}
~~~

**AEM will be configured as defined in the [Minimal Example](/docs/aem-instance/Minimal.md), with the following additions:**

* Run using additional runmodes: *dev*, *server*, *mock*

