## Reverse Replication Agent Examples

The `aem::agent::replication::reverse` resource allows you to create and manage specific Reverse Replication Agents.

[See Documentation](https://docs.adobe.com/docs/en/aem/6-2/deploy/configuring/replication.html#Configuring%20your%20Replication%20Agents)

This example creates a Publish replication agent using the  custom type.

~~~ puppet
$def = '
/content/geo* ${path}.html?wcmmode=preview
/content/dam* ${path}
/content/geo* /content/geometrixx/en.topnav.html
/etc/design/* ${path}'


aem::agent::replication::static { 'Static Agent' :
  definition => $def,
  directory  => '/tmp',
  home       => '/opt/aem',
  name       => 'static',
  password   => 'admin',
  runmode    => 'author',
  username   => 'admin',
}
~~~

This will create a Reverse replication agent at the path: _/etc/replication/agents.author/static_.
