# AEM Service

## Running Service Example

AEM Service is running, but not enabled it on boot:

~~~ puppet
aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  status => 'unmanaged',
}

aem::service { 'aem' :
  home   => '/opt/aem',
  status => 'running',
}

Aem::Instance['aem'] ~> Aem::Service['aem']
~~~
