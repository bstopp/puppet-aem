# AEM Instance

## Specify Sample Content Example

You can disable the sample content (Geometrixx) that comes with AEM. This sets the additional runmode `samplecontent` or `nosamplecontent` depending on the parameter value. Once an instance is created, changing the definition will update the associated configuration script. However this update will have no impact on the operation of the AEM instance. (See [AEM documentation](https://docs.adobe.com/docs/en/aem/6-1/deploy/configuring/configure-runmodes.html#Using samplecontent and nosamplecontent))

~~~ puppet
aem::instance { 'aem' :
  source         => '/path/to/aem-quickstart.jar',
  sample_content => false,
}
~~~

**AEM will be configured as defined in the [Minimal Example](/docs/aem-instance/Minimal.md), with the following changes:**

* Sample content will *not* be included.
