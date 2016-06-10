
### Enable TTL Example

[See Documentation](https://docs.adobe.com/docs/en/dispatcher/disp-config.html#Configuring%20Time%20Based%20Cache%20Invalidation%20-%20/enableTTL)

~~~ puppet
aem::dispatcher::farm { 'site' :
  docroot   => '/var/www/docroot',
  cache_ttl => '1',
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

    /enableTTL "1"
  }
}
~~~
