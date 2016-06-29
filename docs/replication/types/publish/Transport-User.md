## Transport User Publish Replication Agent Example

[See Documentation](https://docs.adobe.com/docs/en/aem/6-2/deploy/configuring/replication.html#Configuring%20your%20Replication%20Agents)

This example creates a Publish replication agent, with a custom transport user credentials.

~~~ puppet
aem::agent::replication::publish { 'Publish Agent' :
  home           => '/opt/aem',
  name           => 'publish',
  password       => 'admin',
  runmode        => 'author',
  trans_password => 'not-the-admin-password',
  trans_uri      => 'http://localhost:4503/bin/receive?authRequestLogin=1',
  trans_user     => 'not-the-admin-user',
  username       => 'admin',
}
~~~
