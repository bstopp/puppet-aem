## Default License Example

This is an example for defining an AEM instance, and a license.

~~~ puppet
aem::instance { 'aem' :
  source         => '/path/to/aem-quickstart.jar',
}

aem::license { 'aem' :
  customer    => 'Customer Name',
  home        => '/opt/aem',
  license_key => 'enter-your-key-here',
  version     => '6.1.0',
}

# Ensure the service doesn't start before license is available

Aem::License['aem'] ~> Aem::Service['aem']
~~~

*The Aem::Service definition created for AEM uses the aem::instance $name to ensure uniqueness, thus here the service reference is 'aem'.*
