## Relaxed SSL Publish Replication Agent Example

[See Documentation](https://docs.adobe.com/docs/en/aem/6-2/deploy/configuring/replication.html#Configuring%20your%20Replication%20Agents)

This example creates a Publish replication agent which will allow an "invalid" cert on the remote system.

~~~ puppet
aem::agent::replication::publish { 'Publish Agent' :
  home                 => '/opt/aem',
  name                 => 'publish',
  password             => 'admin',
  runmode              => 'author',
  trans_allow_exp_cert => true,
  trans_password       => 'admin',
  trans_ssl            => 'relaxed',
  trans_uri            => 'http://localhost:4503/bin/receive?authRequestLogin=1',
  trans_user           => 'admin',
  username             => 'admin',
}
~~~
