
## Specify Context Root Example

You can specify the context root for URL resolution. (See [Sling documentation](https://sling.apache.org/documentation/the-sling-engine/the-sling-launchpad.html#command-line-options))

~~~ puppet
aem::instance { 'aem' :
  source       => '/path/to/aem-quickstart.jar',
  context_root => 'custom-path'
}
~~~

**AEM will be configured as defined in the [Minimal Example](docs/aem-instance/Minimal.md), with the following additions:**

* Use context root *custom-path*; i.e. AEM home page will be: http://localhost:4502/custom-path/

