# Generic Publish Replication Agent Exmaple

# This is an example of how to create a Publish replication agent
# using the generic resource definition.

aem::agent::replication { 'Flush Agent' :
  home            => '/opt/aem',
  name            => 'flush',
  password        => 'admin',
  resource_type   => 'cq/replication/components/agent',
  runmode         => 'author',
  serialize_type  => 'flush',
  template        => '/libs/cq/replication/templates/agent',
  trans_uri       => 'http://localhost:80/dispatcher/invlaidate.cache',
  username        => 'admin',
}