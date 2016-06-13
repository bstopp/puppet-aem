# Manage service separtely and have it disabled.

aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  status => 'unmanaged',
}

aem::service { 'aem' :
  home   => '/opt/aem',
  status => 'disabled',
}

Aem::Instance['aem'] ~> Aem::Service['aem']