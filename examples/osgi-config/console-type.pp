# Console OSGi Configurations

# Remove Existing properties when persisting.

$cfgs = {
  'index.files' => [ 'index', 'index.html', 'index.htm' ]
}

aem::osgi::config { 'org.apache.sling.servlets.get.DefaultGetServlet' :
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

aem::osgi::config { 'org.apache.sling.servlets.get.DefaultGetServlet' :
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

aem::osgi::config { 'org.apache.sling.servlets.get.DefaultGetServlet-Author' :
  ensure         => present,
  pid            => 'org.apache.sling.servlets.get.DefaultGetServlet',
  properties     => $cfgs,
  handle_missing => 'merge',
  home           => '/opt/aem/author',
  password       => 'admin',
  type           => 'console',
  username       => 'admin',
}
