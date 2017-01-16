# Replication

## Reverse Replication Agent Examples

The `aem::agent::replication::reverse` resource allows you to create and manage specific Reverse Replication Agents.

[See Documentation](https://docs.adobe.com/docs/en/aem/6-2/deploy/configuring/replication.html#Configuring%20your%20Replication%20Agents)

This example creates a Reverse replication agent, the custom type.

~~~ puppet
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
~~~

This will create a Reverse replication agent at the path: _/etc/replication/agents.author/publish_reverse_.
