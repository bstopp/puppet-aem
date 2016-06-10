
## Console Examples

If **type** is set to *console*, the provider will use a API call to the Felix Web Console to update the OSGi configuration

* [Remove Existing](#remove-existing)
* [Merge Existing](#merge-existing)
* [Existing w/ PID](#existing-w-pid)


### Remove Existing

Setting the **handle_missing** parameter to *remove* will delete any existing settings and only pass the specified parameters.

By default the Sling Default Get Servlet is configured with:

* aliases => *xml:pdf*
* index.files => *[ 'index', 'index.html' ]*
* enable.json => *true*
* json.maximumresults => *1000*

The following will remove all of the values above and replace it with:

* index.files => *[ 'index', 'index.html', 'index.htm' ]*

~~~ puppet
$cfgs = {
  'index.files' => [ 'index', 'index.html', 'index.htm' ]
}

aem::osgi::config { 'org.apache.sling.security.impl.ReferrerFilter' :
  ensure         => present,
  properties     => $cfgs,
  handle_missing => 'remove\',
  home           => '/opt/aem/author',
  password       => 'admin',
  type           => 'console',
  username       => 'admin',
}
~~~

### Merge Existing 

Setting the **handle_missing** parameter to *merge* will ensure any already existing parameters are still set, even if not specified in the Puppet resource definition.

By default the Sling Default Get Servlet is configured with:

* aliases => *xml:pdf*
* index.files => *[ 'index', 'index.html' ]*
* enable.json => *true*
* json.maximumresults => *1000*

The following will remove all of the values above and replace it with:

* aliases => *xml:pdf*
* index.files => *[ 'index', 'index.html', 'index.htm' ]*
* enable.json => *true*
* json.maximumresults => *1000*

~~~ puppet
$cfgs = {
  'index.files' => [ 'index', 'index.html', 'index.htm' ]
}

aem::osgi::config { 'org.apache.sling.security.impl.ReferrerFilter' :
  ensure         => present,
  properties     => $cfgs,
  handle_missing => 'merge',
  home           => '/opt/aem/author',
  password       => 'admin',
  type           => 'console',
  username       => 'admin',
}
~~~

### Existing w/ PID

Setting the **handle_missing** parameter to *merge* will ensure any already existing parameters are still set, even if not specified in the Puppet resource definition.

By default the Sling Default Get Servlet is configured with:

* aliases => *xml:pdf*
* index.files => *[ 'index', 'index.html' ]*
* enable.json => *true*
* json.maximumresults => *1000*

The following will remove all of the values above and replace it with:

* aliases => *xml:pdf*
* index.files => *[ 'index', 'index.html', 'index.htm' ]*
* enable.json => *true*
* json.maximumresults => *1000*

~~~ puppet
$cfgs = {
  'index.files' => [ 'index', 'index.html', 'index.htm' ]
}

aem::osgi::config { 'org.apache.sling.security.impl.ReferrerFilter-Author' :
  ensure         => present,
  pid            => 'org.apache.sling.security.impl.ReferrerFilter',
  properties     => $cfgs,
  handle_missing => 'merge',
  home           => '/opt/aem/author',
  password       => 'admin',
  type           => 'console',
  username       => 'admin',
}
~~~
