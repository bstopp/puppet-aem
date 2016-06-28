
# Custom User/Group Service Example

aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  status => 'unmanaged',
  user   => 'vagrant',
  group  => 'vagrant',
}

aem::service { 'aem' :
  home  => '/opt/aem',
  user  => 'vagrant',
  group => 'vagrant',
}

Aem::Instance['aem'] ~> Aem::Service['aem']