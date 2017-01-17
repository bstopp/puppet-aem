# Dispatcher - Cache Rules

### Statfile Example

[See Documentation](https://docs.adobe.com/docs/en/dispatcher/disp-config.html#Naming%20the%20Statfile)

Custom statfile definition:

~~~ puppet
aem::dispatcher::farm { 'site' :
  docroot   => '/var/www',
  stat_file => '/path/to/statfile',
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

    /statfile "/path/to/statfile"

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