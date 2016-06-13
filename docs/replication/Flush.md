## Generic Flush Replication Agent Example

[See Documentation](https://docs.adobe.com/docs/en/aem/6-2/deploy/configuring/replication.html#Configuring%20your%20Replication%20Agents)

This example creates a generic Flush replication agent:

~~~ puppet
aem::agent::replication { 'Flush Agent' :
  home            => '/opt/aem',
  name            => 'flush',
  password        => 'admin',
  resource_type   => 'cq/replication/components/agent',
  runmode         => 'author',
  serialize_type  => 'flush',
  template        => '/libs/cq/replication/templates/agent',
  trans_uri       => 'http://localhost:80/dispatcher/invalidate.cache',
  username        => 'admin',
}
~~~

This will create a Flush replication agent at the path: _/etc/replication/agents.author/flush_.
