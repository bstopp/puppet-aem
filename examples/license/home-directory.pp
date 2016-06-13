
# Custom Home Directory Example

aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  home   => '/opt/aem/author',
}

aem::license { 'aem' :
  customer    => 'Customer Name',
  home        => '/opt/aem/author',
  license_key => 'enter-your-key-here',
  version     => '6.1.0',
}

Aem::License['aem'] ~> Aem::Service['aem-aem']
