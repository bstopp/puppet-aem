# AEM Service

## Custom Home Directory Service Example

In the event you changed the default AEM installation folder:

~~~ puppet
aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  status => 'unmanaged',
  home   => '/opt/aem/author',
}

aem::service { 'aem' :
  home => '/opt/aem/author',
}

Aem::Instance['aem'] ~> Aem::Service['aem']
~~~
