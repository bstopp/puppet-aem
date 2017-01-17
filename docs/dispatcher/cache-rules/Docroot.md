# Dispatcher - Cache Rules

### Docroot Example

[See Documentation](https://docs.adobe.com/docs/en/dispatcher/disp-config.html#Specifying%20the%20Cache%20Directory)

The default definition requires a docroot:

~~~ puppet
aem::dispatcher::farm { 'site' :
  docroot => '/var/www/docroot',
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
  }
}
~~~