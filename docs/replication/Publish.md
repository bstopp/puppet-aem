# Replication

## Generic Publish Replication Agent Example

[See Documentation](https://docs.adobe.com/docs/en/aem/6-2/deploy/configuring/replication.html#Configuring%20your%20Replication%20Agents)

This example creates a generic Publish replication agent:

~~~ puppet
aem::agent::replication { 'Publish Agent' :
  home            => '/opt/aem',
  name            => 'publish',
  password        => 'admin',
  resource_type   => 'cq/replication/components/agent',
  runmode         => 'author',
  serialize_type  => 'durbo',
  template        => '/libs/cq/replication/templates/agent',
  trans_password  => 'admin',
  trans_uri       => 'http://localhost:4503/bin/receive?authRequestLogin=1',
  trans_user      => 'admin',
  username        => 'admin',
}
~~~

This will create a Publish replication agent at the path: _/etc/replication/agents.author/publish_.
