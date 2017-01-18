# Replication - Flush Agent

## Relaxed SSL Flush Replication Agent Example

[See Documentation](https://docs.adobe.com/docs/en/aem/6-2/deploy/configuring/replication.html#Configuring%20your%20Replication%20Agents)

This example creates a Flush replication agent which will allow an "invalid" (self-signed) certs on the remote system.

~~~ puppet
aem::agent::replication::flush { 'Flush Agent' :
  home                 => '/opt/aem',
  name                 => 'flush',
  password             => 'admin',
  runmode              => 'author',
  trans_allow_exp_cert => true,
  trans_password       => 'admin',
  trans_ssl            => 'relaxed',
  trans_uri            => 'http://localhost:80/dispatcher/invalidate.cache',
  trans_user           => 'admin',
  username             => 'admin',
}
~~~
