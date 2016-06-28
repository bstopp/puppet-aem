# Reverse Replication Agent Exmaple

# This is an example of how to create a Reverse replication agent
# using the reverse custom type.

aem::agent::replication::reverse { 'Reverse Agent' :
  home           => '/opt/aem',
  name           => 'publish_reverse',
  password       => 'admin',
  runmode        => 'author',
  trans_password => 'admin',
  trans_uri      => 'http://localhost:4503/bin/receive?authRequestLogin=1',
  trans_user     => 'admin',
  username       => 'admin',
}