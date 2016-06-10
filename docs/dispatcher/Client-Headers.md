
## Client Headers Farm Example

[See Documentation](https://docs.adobe.com/docs/en/dispatcher/disp-config.html#Specifying%20the%20HTTP%20Headers%20to%20Pass%20Through%20-%20/clientheaders)

This example creates a Farm definition with custom client header definition:

~~~ puppet
aem::dispatcher::farm { 'site' :
  docroot        => '/var/www',
  client_headers => [
    'A-Client-Header',
    'Another-Client-Header'
  ],
}
~~~

This definition will create a file *dispatcher.site.any* with the following contents:

~~~
/anothersite {

  /clientheaders {
    "A-Client-Header"
    "Another-Client-Header"
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
}
~~~
