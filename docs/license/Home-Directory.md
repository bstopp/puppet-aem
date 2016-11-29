
## Custom Home Directory Example

In the event you changed the default AEM installation folder, this example will move the license to the correct location.

~~~ puppet
aem::instance { 'aem' :
  source => '/path/to/aem-quickstart.jar',
  home   => '/opt/aem/author',
}

aem::license { 'aem' :
  customer    => 'Customer Name',
  home        => '/opt/aem/author',
  license_key => 'enter-your-key-here',
  version     => '6.1.0',
}

Aem::License['aem'] ~> Aem::Service['aem']
~~~

*The Aem::Service definition created for AEM uses the aem::instance $name to ensure uniqueness, thus here the service reference is 'aem'.*
