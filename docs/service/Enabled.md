## Enabled Service Example

Enable AEM Service, using separate resource configuration, you have to disable the default service management:

~~~ puppet
aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  status => 'unmanaged',
}

aem::service { 'aem' :
  home   => '/opt/aem,
}

Aem::Instance['aem'] ~> Aem::Service['aem']
~~~
