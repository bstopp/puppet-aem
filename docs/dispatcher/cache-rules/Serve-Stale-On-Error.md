
### Serve Stale On Error Example

[See Documentation](https://docs.adobe.com/docs/en/dispatcher/disp-config.html#Serving%20Stale%20Documents%20When%20Errors%20Occur)

Custom Serve Stale on Error definition:

~~~ puppet
aem::dispatcher::farm { 'site' :
  docroot     => '/var/www',
  serve_stale => 1,
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

    /serveStaleOnError "1"

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