
# Specify runmodes Example
#
# Add custom rundmoes of dev, server, and mock.

aem::instance { 'aem' :
  source   => '/path/to/aem-quickstart.jar',
  runmodes => ['dev', 'server', 'mock'],
}
