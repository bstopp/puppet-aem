# AEM Instance

## Specify Port Example

You can specify the port on which AEM will listen. (See [AEM documentation](https://docs.adobe.com/docs/en/aem/6-1/deploy/custom-standalone-install.html#Changing the Port Number by Renaming the File))

~~~ puppet
aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  port   => 8080,
}
~~~

**AEM will be configured as defined in the [Minimal Example](/docs/aem-instance/Minimal.md), with the following changes:**

* Listen on port: 8080
