## File Type Example

If the **type** is set to *file*, a file will be created in the *<home>/crx-quickstart/install* folder.

**Note**: File OSGi Configurations only seem to be ready before the AEM instance starts for the first time. This is a funcion of AEM; not a failure of the module to create the defined file.

This example sets the Referrer Filter to allow the host *author.localhost* and *vagrant.localhost*.

~~~ puppet
$cfgs = {
  'allow.hosts' => ['author.localhost', 'vagrant.localhost']
}

aem::osgi::config { 'org.apache.sling.security.impl.ReferrerFilter' :
  ensure     => 'present',
  properties => $cfgs,
  group      => 'admin',
  home       => '/opt/aem/author',
  type       => 'file',
  user       => 'admin',
}
~~~

## File Type Example w/ PID

If the **type** is set to *file*, a file will be created in the *<home>/crx-quickstart/install* folder.

**Note**: File OSGi Configurations only seem to be ready before the AEM instance starts for the first time. This is a funcion of AEM; not a failure of the module to create the defined file.

This example sets the Referrer Filter to allow the host *author.localhost* and *vagrant.localhost*.

~~~ puppet
$cfgs = {
  'allow.hosts' => ['author.localhost', 'vagrant.localhost']
}

aem::osgi::config { 'org.apache.sling.security.impl.ReferrerFilter-Author' :
  ensure     => 'present',
  pid        => 'org.apache.sling.security.impl.ReferrerFilter',
  properties => $cfgs,
  group      => 'admin',
  home       => '/opt/aem/author',
  type       => 'file',
  user       => 'admin',
}
~~~