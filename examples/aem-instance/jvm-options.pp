# Custom JVM Settings
#
# Define Custom Garage Collection rules for the JVM.
aem::instance { 'aem' :
  source   => '/path/to/aem-quickstart.jar',
  jvm_opts => 'XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCDateStamps \
               -XX:+PrintTenuringDistribution -XX:+PrintGCApplicationStoppedTime -XX:+HeapDumpOnOutOfMemoryError'
}