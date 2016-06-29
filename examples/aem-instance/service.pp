
# Unmanaged Service Example
#
# Do not manage the service via puppet.
aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  status => 'unmanaged'
}

# Disabled Service Example

aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  status => 'disabled'
}

# Running Service Example
#
# AEM should be running now, but not started on system book.

aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  status => 'running'
}
