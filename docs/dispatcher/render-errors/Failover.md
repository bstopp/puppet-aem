# Dispatcher - Render Errors

### Failover Example

[See Documentation](https://docs.adobe.com/docs/en/dispatcher/disp-config.html#Using%20the%20Failover%20Mechanism)

~~~ puppet
aem::dispatcher::farm { 'site' :
  docroot  => '/var/www',
  failover => 1,
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

  /failover "1"
}
~~~