
## Propagate Synd Post Farm Example

[See Documentation](https://docs.adobe.com/docs/en/dispatcher/disp-config.html#Forwarding%20Syndication%20Requests%20-%20/propagateSyndPost)

This example creates a farm definition with custom Propagate Synd Post:

~~~ puppet
aem::dispatcher::farm { 'site' :
  docroot => '/var/www',
  propagate_synd_post => '1',
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

  /propagateSyndPost "1"

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
