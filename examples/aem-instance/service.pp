
# Unmanaged Service Example
#
# Do not manage the service via puppet.
aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  service => 'unmanaged'
}

# Disabled Service Example

aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  service => 'disabled'
}

# Running Service Example
#
# AEM should be running now, but not started on system book.

aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  service => 'running'
}
