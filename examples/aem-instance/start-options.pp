# Custom Quickstart start options
#
# Define Custom Garage Collection rules for the JVM.
aem::instance { 'aem' :
  source     => '/path/to/aem-quickstart.jar',
  start_opts => '-nofork'
}
