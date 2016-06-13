## Default Publish Replication Agent Example

[See Documentation](https://docs.adobe.com/docs/en/aem/6-2/deploy/configuring/replication.html#Configuring%20your%20Replication%20Agents)

This example creates a Publish replication agent, using the minimal resource definition.

~~~ puppet
aem::agent::replication::flush { 'Flush Agent' :
  home            => '/opt/aem',
  name            => 'flush',
  password        => 'admin',
  runmode         => 'author',
  trans_password  => 'admin',
  trans_uri       => 'http://localhost:80/dispatcher/invalidate.cache',
  trans_user      => 'admin',
  username        => 'admin',
}
~~~

This will create a Flush replication agent at the path: _/etc/replication/agents.author/flush_.
