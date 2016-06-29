
## Filters Farm Example

[See Documentation](https://docs.adobe.com/docs/en/dispatcher/disp-config.html#Configuring%20Access%20to%20Content%20-%20/filter)

* [Glob Example](#glob-example)
* [Advanced Example](#advanced-example)

A filter hash supports a *rank* configuration attribute. This is used to prioritize the order in which the filters are output, the lower the number the higher in the sequence. Default rank is *-1*.

There are two methods for defining a Filter hash. If the hash contains the _glob_ key, then only the _type_ and _glob_ values will be used. Otherwise the advanced attributes are used, which contain:

  * type
  * url
  * query
  * protocol
  * path
  * selectors
  * extension
  * suffix

#### Glob Example

This example creates a Farm definition with custom filter rules, using a glob example:

~~~ puppet
aem::dispatcher::farm { 'site' :
  docroot => '/var/www',
  filters => [
    { 
      'rank' => 310, 
      'type' => 'allow',
      'glob' => '*.html',
    },
    {
      'rank' => 300,
      'type' => 'deny',
      'glob' => '*',
    }
  ],
}
~~~

This definition will create a file *dispatcher.site.any* with the following contents:

~~~
/anothersite {

  /clientheaders {
    "*"
  }

  /virtualhosts {
    "*"
  }

  /renders {
    /renderer0 { 
      /hostname "localhost"
      /port "4503"
    }
  }

  /filter {
    /0 { /type "deny" /glob "*" }
    /1 { /type "allow" /glob "*.html" }
  }

  /cache {

    /docroot "/var/www"

    /rules {
      /0 { /type "deny" /glob "*" }
    }

    /invalidate {
      /0 { /type "allow" /glob "*" }
    }

    /allowedClients {
      /0 { /type "allow" /glob "*" }
    }
  }
}
~~~

#### Advanced Example

This example creates a Farm definition with custom filter rules, using a glob example:

~~~ puppet
aem::dispatcher::farm { 'site' :
  docroot => '/var/www',
  filters => [
    {
      'rank'      => 310,
      'type'      => 'allow',
      'path'      => '/content',
      'selectors' => '(feed|rss|pages|languages|blueprint|infinity|tidy)'
      'extension' => '(json|xml|html)'
    },
    {
      'rank' => 300,
      'type' => 'deny',
      'glob' => '*',
    }
  ],
}
~~~

This definition will create a file *dispatcher.site.any* with the following contents:

~~~
/anothersite {

  /clientheaders {
    "*"
  }

  /virtualhosts {
    "*"
  }

  /renders {
    /renderer0 {
      /hostname "localhost"
      /port "4503"
    }
  }

  /filter {
    /0 { /type "deny" /glob "*" }
    /1 {
      /type "allow"
      /path "/content"
      /selectors '(feed|rss|pages|languages|blueprint|infinity|tidy)'
      /extension '(json|xml|html)'
    }
  }

  /cache {

    /docroot "/var/www"

    /rules {
      /0 { /type "deny" /glob "*" }
    }

    /invalidate {
      /0 { /type "allow" /glob "*" }
    }

    /allowedClients {
      /0 { /type "allow" /glob "*" }
    }
  }
}
~~~
