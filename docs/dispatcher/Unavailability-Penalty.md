# Dispatcher

## Unavailablity Penalty Example

[See Documentation](https://docs.adobe.com/docs/en/dispatcher/disp-config.html#Reflecting%20Server%20Unavailability%20in%20Dispatcher%20Statistics)

~~~ puppet
aem::dispatcher::farm { 'site' :
  docroot             => '/var/www',
  statistics          => [
    {
      'glob'     => '*.html',
      'category' => 'html'
    },
    {
      'glob'     => '*',
      'category' => 'others'
    }
  ],
  unavailable_penalty => '2',
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

  /statistics {
    /categories {
      /html { /glob "*.html" }
      /others { /glob "*" }
    }
  }

  /unavailablePenalty "2"

}
~~~
