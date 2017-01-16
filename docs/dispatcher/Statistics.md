# Dispatcher

## Statistics Farm Example

[See Documentation](https://docs.adobe.com/docs/en/dispatcher/disp-config.html#Configuring%20Load%20Balancing%20-%20/statistics)

The *rank* configuration is used to prioritize the order in which the statistic categories are output, the lower the number the higher in the sequence. Default rank is *-1*.

This example creates a Farm definition with custom session management definition:

~~~ puppet
aem::dispatcher::farm { 'site' :
  docroot    => '/var/www',
  statistics => [
    {
      'rank'     => 310,
      'glob'     => '*',
      'category' => 'others'
    },
    {
      'rank'     => 300,
      'glob'     => '*.html',
      'category' => 'html'
    },
  ],
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

}
~~~
