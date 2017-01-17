# Dispatcher - Cache Rules

### Invalidate Handler Example

[See Documentation](https://docs.adobe.com/docs/en/dispatcher/disp-config.html#Using%20custom%20invalidation%20scripts)

Specifying the Stat Files Level:

~~~ puppet
aem::dispatcher::farm { 'site' :
  docroot            => '/var/www',
  invalidate_handler => '/path/to/handler',
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

    /allowAuthorized "1"

    /rules {
      /0 { /type "deny" /glob "*" }
    }

    /statfileslevel "3"

    /invalidateHandler "/path/to/handler"

    /allowedClients {
      /0 { /type "allow" /glob "*" }
    }
  }
}
~~~