# Dispatcher - Cache Rules

### Cache Headers Example

[See Documentation](https://docs.adobe.com/docs/en/dispatcher/disp-config.html#Caching%20HTTP%20Response%20Headers)

~~~ puppet
aem::dispatcher::farm { 'site' :
  docroot       => '/var/www/docroot',
  cache_headers => [
    'A-Cache-Header',
    'Another-Cache-Header'
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
    /0 { /type "allow" /glob "*" }
  }

  /cache {

    /docroot "/var/www/docroot"

    /rules {
      /0 { /type "deny" /glob "*" }
    }

    /invalidate {
      /0 { /type "allow" /glob "*" }
    }

    /allowedClients {
      /0 { /type "allow" /glob "*" }
    }

    /headers {
      "A-Cache-Header"
      "Another-Cache-Header"
    }

  }
}
~~~
[back to top](#cache-rules-farm-examples)