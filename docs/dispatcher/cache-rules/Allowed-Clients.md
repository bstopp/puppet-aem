# Dispatcher - Cache Rules

### Allowed Clients Example

[See Documentation](https://docs.adobe.com/docs/en/dispatcher/disp-config.html#Limiting%20the%20Clients%20That%20Can%20Flush%20the%20Cache)

The *rank* configuration is used to prioritize the order in which the allowed clients are output, the lower the number the higher in the sequence. Default rank is *-1*.

Specifying the Allowed Flush Clients:

~~~ puppet
aem::dispatcher::farm { 'site' :
  docroot         => '/var/www',
  allowed_clients => [
    {
      'rank' => 310,
      'type' => 'allow',
      'glob' => '127.0.0.1'
    },
    {
      'rank' => 300,
      'type' => 'deny',
      'glob' => '*'
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

    /allowAuthorized "1"

    /rules {
      /0 { /type "deny" /glob "*" }
    }

    /statfileslevel "3"

    /invalidate {
      /0 { /type "allow" /glob "*" }
    }

    /allowedClients {
      /0 { /type "deny" /glob "*" }
      /1 { /type "allow" /glob "127.0.0.1" }
    }

  }
}
~~~