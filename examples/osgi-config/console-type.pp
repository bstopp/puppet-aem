# Console OSGi Configurations

# Remove Existing properties when persisting.

$cfgs = {
  'index.files' => [ 'index', 'index.html', 'index.htm' ]
}

aem::osgi::config { 'org.apache.sling.security.impl.ReferrerFilter' :
  ensure         => present,
  properties     => $cfgs,
  handle_missing => 'remove',
  home           => '/opt/aem/author',
  password       => 'admin',
  type           => 'console',
  username       => 'admin',
}


# Merge Existing properties when persisting.

$cfgs = {
  'index.files' => [ 'index', 'index.html', 'index.htm' ]
}

aem::osgi::config { 'org.apache.sling.security.impl.ReferrerFilter' :
  ensure         => present,
  properties     => $cfgs,
  handle_missing => 'merge',
  home           => '/opt/aem/author',
  password       => 'admin',
  type           => 'console',
  username       => 'admin',
}


# Congiruation using w/ PID parameter

$cfgs = {
  'index.files' => [ 'index', 'index.html', 'index.htm' ]
}

aem::osgi::config { 'org.apache.sling.security.impl.ReferrerFilter-Author' :
  ensure         => present,
  pid            => 'org.apache.sling.security.impl.ReferrerFilter',
  properties     => $cfgs,
  handle_missing => 'merge',
  home           => '/opt/aem/author',
  password       => 'admin',
  type           => 'console',
  username       => 'admin',
}
