
## Filters Farm Example

[See Documentation](https://docs.adobe.com/docs/en/dispatcher/disp-config.html#Configuring%20Access%20to%20Content%20-%20/filter)

This example creates a Farm definition with custom filter rules.

The *rank* configuration is used to prioritize the order in which the filters are output, the lower the number the higher in the sequence. Default rank is *-1*.

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
