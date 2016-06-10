
## Virtual Hosts Farm Example

[See Documentation](https://docs.adobe.com/docs/en/dispatcher/disp-config.html#Identifying%20Virtual%20Hosts%20-%20/virtualhosts)

This example creates a Farm definition with custom virtual host definition:

~~~ puppet
aem::dispatcher::farm { 'site' :
  docroot      => '/var/www',
  virtualhosts => [
    'www.avirtualhost.com',
    'another.virtual.com'
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
    "www.avirtualhost.com"
    "another.virtual.com"
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
}
~~~
