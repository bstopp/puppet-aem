# Manage service separtely and have it running.

aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  status => 'unmanaged',
}

aem::service { 'aem' :
  home   => '/opt/aem',
  status => 'running',
}

Aem::Instance['aem'] ~> Aem::Service['aem']