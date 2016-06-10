
# Specify Type Example
#
# Create a publish instance.

aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  type   => 'publish',
}
