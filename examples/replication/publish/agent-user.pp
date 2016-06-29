# Agent User Publish Replication Agent Example

# This example configures the agent to use a specific user for aggregating content.

aem::agent::replication::publish { 'Publish Agent' :
  agent_user     => 'custom-user',
  home           => '/opt/aem',
  name           => 'publish',
  password       => 'admin',
  runmode        => 'author',
  trans_password => 'admin',
  trans_uri      => 'http://localhost:4503/bin/receive?authRequestLogin=1',
  trans_user     => 'admin',
  username       => 'admin',
}

