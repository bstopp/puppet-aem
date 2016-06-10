# File Type Example

# OSGi Configuration with the PID as the resource title.
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

# File Type Example w/ PID parameter
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
