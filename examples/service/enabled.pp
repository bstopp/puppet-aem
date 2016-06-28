# Manage service separtely and have it enabled.

aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  status => 'unmanaged',
}

aem::service { 'aem' :
  home => '/opt/aem',
}

Aem::Instance['aem'] ~> Aem::Service['aem']