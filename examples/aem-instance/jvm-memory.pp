
# Specify JVM Memory Example
#
# Start with 4G of Heap memory

aem::instance { 'aem' :
  source       => '/path/to/aem-quickstart.jar',
  jvm_mem_opts => '-Xmx4096m'
}


# Specify JVM Memory w/ Perm Gen Example
#
# Specify with 1G of Perm Gen memory.

aem::instance { 'aem' :
  source       => '/path/to/aem-quickstart.jar',
  jvm_mem_opts => '-Xmx4096m -XX:MaxPermSize=1024m'
}
