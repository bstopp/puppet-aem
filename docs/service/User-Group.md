## Custom User/Group Service Example

In the event you changed the default AEM user/group.

~~~ puppet
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
~~~

