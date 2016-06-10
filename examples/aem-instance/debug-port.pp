# Debug Port example
#
# Start AEM listening for debug connections on port 30303.

aem::instance { 'aem' :
  source     => '/path/to/aem-quickstart.jar',
  debug_port => 30303,
}