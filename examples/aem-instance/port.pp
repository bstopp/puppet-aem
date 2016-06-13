
# Specify Port Example
#
# AEM will listen on port 8080.

aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  port   => 8080,
}
