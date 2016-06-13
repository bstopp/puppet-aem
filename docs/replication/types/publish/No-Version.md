## No Versioning Publish Replication Agent Example

[See Documentation](https://docs.adobe.com/docs/en/aem/6-2/deploy/configuring/replication.html#Configuring%20your%20Replication%20Agents)

This example disables the versioning of content when it is replicated.

~~~ puppet
aem::agent::replication::publish { 'Publish Agent' :
  home               => '/opt/aem',
  name               => 'publish',
  password           => 'admin',
  runmode            => 'author',
  trigger_no_version => true,
  trans_password     => 'admin',
  trans_uri          => 'http://localhost:4503/bin/receive?authRequestLogin=1',
  trans_user         => 'admin',
  username           => 'admin',
}
~~~
