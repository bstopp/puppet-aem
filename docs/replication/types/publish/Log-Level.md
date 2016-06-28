## Log-Level Publish Replication Agent Example

[See Documentation](https://docs.adobe.com/docs/en/aem/6-2/deploy/configuring/replication.html#Configuring%20your%20Replication%20Agents)

This example manages the Log Level for the replication agent.

~~~ puppet
aem::agent::replication::publish { 'Publish Agent' :
  home           => '/opt/aem',
  log_level      => 'error',
  name           => 'publish',
  password       => 'admin',
  runmode        => 'author',
  trans_password => 'admin',
  trans_uri      => 'http://localhost:4503/bin/receive?authRequestLogin=1',
  trans_user     => 'admin',
  username       => 'admin',
}
~~~
