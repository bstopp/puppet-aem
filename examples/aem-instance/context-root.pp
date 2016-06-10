
# Specify Context Root Example
#
# Specify the context root as '/custom-path

aem::instance { 'aem' :
  source       => '/path/to/aem-quickstart.jar',
  context_root => 'custom-path'
}

