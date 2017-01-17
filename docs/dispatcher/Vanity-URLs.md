# Dispatcher

## Vanity URLs Farm Example

[See Documentation](https://docs.adobe.com/docs/en/dispatcher/disp-config.html#Enabling%20Access%20to%20Vanity%20URLs%20-%20/vanity_urls)

This example creates a Farm with a custom vanity URL section:

~~~ puppet
aem::dispatcher::farm { 'site' :
  docroot     => '/var/www',
  vanity_urls => {
    'file'  => '/path/to/cache',
    'delay' => 600,
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
      /hostname "localhost"
      /port "4503"
    }
  }

  /filter {
    /0 { /type "allow" /glob "*" }
  }

  /vanity_urls {
    /url "/libs/granite/dispatcher/content/vanityUrls.html"
    /file "/path/to/cache"
    /delay "600"
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
