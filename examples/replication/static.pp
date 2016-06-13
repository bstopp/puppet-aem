# Static Replication Agent Exmaple

# This is an example of how to create a Static replication agent
# using the custom type.

$def = '
/content/geo* ${path}.html?wcmmode=preview
/content/dam* ${path}
/content/geo* /content/geometrixx/en.topnav.html
/etc/design/* ${path}'


aem::agent::replication::static { 'Static Agent' :
  definition => $def,
  directory  => '/tmp',
  home       => '/opt/aem',
  name       => 'static',
  password   => 'admin',
  runmode    => 'author',
  username   => 'admin',
}