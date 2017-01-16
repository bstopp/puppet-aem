# Dispatcher - Cache Rules

### Stat Files Level Example

[See Documentation](https://docs.adobe.com/docs/en/dispatcher/disp-config.html#Invalidating%20Files%20by%20Folder%20Level)

Specifying the Stat Files Level:

~~~ puppet
aem::dispatcher::farm { 'site' :
  docroot          => '/var/www',
  stat_files_level => 3,
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

    /invalidate {
      /0 { /type "allow" /glob "*" }
    }

    /allowedClients {
      /0 { /type "allow" /glob "*" }
    }
  }
}
~~~