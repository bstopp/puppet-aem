## Disabled Service Example

AEM Service is not running, and not enabled it on boot:

~~~ puppet
aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  status => 'unmanaged',
}

aem::service { 'aem' :
  home   => '/opt/aem',
  status => 'disabled',
}

Aem::Instance['aem'] ~> Aem::Service['aem']
~~~