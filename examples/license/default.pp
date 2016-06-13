# Default License Example

aem::instance { 'aem' :
  source         => '/path/to/aem-quickstart.jar',
}

aem::license { 'aem' :
  customer    => 'Customer Name',
  home        => '/opt/aem',
  license_key => 'enter-your-key-here',
  version     => '6.1.0',
}

# Ensure the service doesn't start before license is available
Aem::License['aem'] ~> Aem::Service['aem-aem']
