
## Renderers Farm Example

[See Documentation](https://docs.adobe.com/docs/en/dispatcher/disp-config.html#Defining%20Page%20Renderers%20-%20/renders)

#### Examples

* [Single](#single-renderer)
* [Multiple](#multiple-renderers)

### Single Renderer

This example creates a Farm definition with custom render definition:

~~~ puppet
aem::dispatcher::farm { 'site' :
  docroot => '/var/www',
  renders => {
    'hostname'       => 'publish.hostname.com',
    'port'           => 8080,
    'timeout'        => 600,
    'receiveTimeout' => 300,
    'ipv4'           => 0,
  },
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
      /hostname "publish.hostname.com"
      /port "8080"
      /timeout "600"
      /receiveTimeout "300"
      /ipv4 "0"
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

### Multiple Renderers

This example creates a Farm definition with multiple render definition:

~~~ puppet
aem::dispatcher::farm { 'site' :
  docroot => '/var/www',
  renders => [
    {
      'hostname'       => 'publish.hostname.com',
      'port'           => 8080,
      'timeout'        => 600,
      'receiveTimeout' => 300,
      'ipv4'           => 0,
    },
    {
      'hostname'       => 'author.hostname.com',
      'port'           => 9009,
    }
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
      /hostname "publish.hostname.com"
      /port "9009"
      /timeout "300"
      /receiveTimeout "100"
    }
    /renderer1 { 
      /hostname "author.hostname.com"
      /port "8080"
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
