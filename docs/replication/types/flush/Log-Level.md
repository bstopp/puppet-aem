## Log-Level Flush Replication Agent Example

[See Documentation](https://docs.adobe.com/docs/en/aem/6-2/deploy/configuring/replication.html#Configuring%20your%20Replication%20Agents)

This example manages the Log Level for the replication agent.

~~~ puppet
aem::agent::replication::flush { 'Flush Agent' :
  home           => '/opt/aem',
  log_level      => 'error',
  name           => 'flush',
  password       => 'admin',
  runmode        => 'author',
  trans_password => 'admin',
  trans_uri      => 'http://localhost:80/dispatcher/invalidate.cache',
  trans_user     => 'admin',
  username       => 'admin',
}
~~~
