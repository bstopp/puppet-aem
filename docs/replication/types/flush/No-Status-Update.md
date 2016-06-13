## No Status Update Flush Replication Agent Example

[See Documentation](https://docs.adobe.com/docs/en/aem/6-2/deploy/configuring/replication.html#Configuring%20your%20Replication%20Agents)

This example disables not update the replication status of content when it is replicated.

~~~ puppet
aem::agent::replication::flush { 'Flush Agent' :
  home              => '/opt/aem',
  name              => 'flush',
  password          => 'admin',
  runmode           => 'author',
  trigger_no_status => true,
  trans_password    => 'admin',
  trans_uri         => 'http://localhost:80/dispatcher/invalidate.cache',
  trans_user        => 'admin',
  username          => 'admin',
}
~~~
