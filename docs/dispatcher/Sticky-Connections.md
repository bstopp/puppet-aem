# Dispatcher

## Sticky Connections Farm Example

[See Documentation](https://docs.adobe.com/docs/en/dispatcher/disp-config.html#Identifying%20a%20Sticky%20Connection%20Folder%20-%20/stickyConnectionsFor)

* [Single Path](#single-path-example)
* [Multiple Paths](#multiple-paths-example)

### Single Path Example

This example creates a default Farm definition:

~~~ puppet
aem::dispatcher::farm { 'site' :
  docroot            => '/var/www',
  sticky_connections => '/path/to/content',

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
    /0 { /type "allow" /glob "*" }
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

  /stickyConnectionsFor "/path/to/content"

}
~~~

### Multiple Paths Example

This example creates a default Farm definition:

~~~ puppet
aem::dispatcher::farm { 'site' :
  docroot            => '/var/www',
  sticky_connections => [
    '/path/to/content',
    '/another/path/to/content'
  ]

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
    /0 { /type "allow" /glob "*" }
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

  /stickyConnections {
    /paths {
      "/path/to/content"
      "/another/path/to/content"
    }
  }

}
~~~
