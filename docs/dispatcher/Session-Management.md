# Dispatcher

## Session Management Farm Example

[See Documentation](https://docs.adobe.com/docs/en/dispatcher/disp-config.html#Enabling%20Secure%20Sessions%20-%20/sessionmanagement)

This example creates a Farm definition with custom session management definition:

~~~ puppet
aem::dispatcher::farm { 'site' :
  docroot            => '/var/www',
  session_management => {
    'directory' => '/path/to/cache',
    'encode'    => 'md5',
    'header'    => 'HTTP:authorization',
    'timeout'   => 1000
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

  /sessionmanagement {
    /directory "/path/to/cache"
    /encode "md5"
    /header "HTTP:authorization"
    /timeout "1000"
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
