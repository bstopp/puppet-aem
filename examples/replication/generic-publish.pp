# Generic Publish Replication Agent Exmaple

# This is an example of how to create a Publish replication agent
# using the generic resource definition.

aem::agent::replication { 'Publish Agent' :
  home           => '/opt/aem',
  name           => 'publish',
  password       => 'admin',
  resource_type  => 'cq/replication/components/agent',
  runmode        => 'author',
  serialize_type => 'durbo',
  template       => '/libs/cq/replication/templates/agent',
  trans_password => 'admin',
  trans_uri      => 'http://localhost:4503/bin/receive?authRequestLogin=1',
  trans_user     => 'admin',
  username       => 'admin',
}