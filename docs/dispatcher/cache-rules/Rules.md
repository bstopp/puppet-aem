### Rules Example

[See Documentation](https://docs.adobe.com/docs/en/dispatcher/disp-config.html#Specifying%20the%20Documents%20to%20Cache)

The *rank* configuration is used to prioritize the order in which the rules are output, the lower the number the higher in the sequence. Default rank is *-1*.

Specifying the Cache Rules:

~~~ puppet
aem::dispatcher::farm { 'site' :
  docroot     => '/var/www',
  cache_rules => [
    {
      'rank' => 310,
      'glob' => '*.html',
      'type' => 'allow'
    },
    {
      'rank' => 300,
      'glob' => '*',
      'type' => 'deny'
    }
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

    /allowAuthorized "1"

    /rules {
      /0 { /type "deny" /glob "*" }
      /1 { /type "allow" /glob "*.html" }
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