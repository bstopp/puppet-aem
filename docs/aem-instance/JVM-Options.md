
## Specify JVM Options Example

You can start with arbitrary JVM Options, if you need to fine tune garbage collection or heap dump on out-of-memory errors.

~~~ puppet
aem::instance { 'aem' :
  source   => '/path/to/aem-quickstart.jar',
  jvm_opts => 'XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCDateStamps -XX:+PrintTenuringDistribution -XX:+PrintGCApplicationStoppedTime -XX:+HeapDumpOnOutOfMemoryError'
}
~~~

**AEM will be configured as defined in the [Minimal Example](docs/aem-instance/Minimal.md), with the following changes:**

* Start with the specified JVM Options above. Basically printing out Garbage collection information and dump the heap on Memory error.

