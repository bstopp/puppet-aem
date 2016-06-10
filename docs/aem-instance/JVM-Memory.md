
## Specify JVM Memory Example

You can start with arbitrary JVM Memory options.

~~~ puppet
aem::instance { 'aem' :
  source       => '/path/to/aem-quickstart.jar',
  jvm_mem_opts => '-Xmx4096m'
}
~~~

**AEM will be configured as defined in the [Minimal Example](docs/aem-instance/Minimal.md), with the following changes:**

* Start with 4G of Heap

## Specify JVM Memory w/ Perm Gen Example

If you're running on Java 7 or lower, you may still need to specify Perm Gen size: 

~~~ puppet
aem::instance { 'aem' :
  source       => '/path/to/aem-quickstart.jar',
  jvm_mem_opts => '-Xmx4096m -XX:MaxPermSize=1024m'
}
~~~

**AEM will be configured as defined in the [Minimal Example](docs/aem-instance/Minimal.md), with the following changes:**

* Start with 4G of Heap Memory and 1G of Perm Gen space.
