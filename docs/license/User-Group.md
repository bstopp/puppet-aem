
## Custom User/Group License Example

In the event you changed the default AEM user/group.

~~~ puppet
aem::instance { 'aem' :
  source  => '/path/to/aem-quickstart.jar',
  service => 'unmanaged',
  user    => 'vagrant',
  group   => 'vagrant',
}

aem::license { 'aem' :
  customer    => 'Customer Name',
  home        => '/opt/aem',
  license_key => 'enter-your-key-here',
  version     => '6.1.0',
  user    => 'vagrant',
  group   => 'vagrant',
}

Aem::License['aem'] ~> Aem::Service['aem-aem']
~~~
